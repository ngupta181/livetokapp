package com.livetok.bubbly_camera

import android.Manifest.permission.CAMERA
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.graphics.*
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.renderscript.*
import android.util.Log
import android.util.Rational
import android.view.LayoutInflater
import android.view.Surface
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import androidx.annotation.RequiresApi
import androidx.camera.core.*
import androidx.camera.core.FocusMeteringAction.FLAG_AE
import androidx.camera.core.FocusMeteringAction.FLAG_AF
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.PermissionChecker
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import androidx.camera.video.VideoRecordEvent
import androidx.camera.video.Recording
import androidx.camera.video.Recorder
import androidx.camera.video.VideoCapture
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.FileOutputOptions
import androidx.camera.core.impl.VideoCaptureConfig
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.*
import jp.co.cyberagent.android.gpuimage.GPUImage
import jp.co.cyberagent.android.gpuimage.filter.*

internal class CameraXView(
    private val context: Activity?,
    id: Int,
    creationParams: Map<String?, Any?>?,
    private val channel: MethodChannel
) :
    PlatformView, MethodChannel.MethodCallHandler {
    private lateinit var camera: androidx.camera.core.Camera
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private lateinit var viewFinder: PreviewView
    private var isBeautyFilterEnabled = false
    private var imageAnalyzer: ImageAnalysis? = null
    private var isRetouchEnabled = false
    private lateinit var faceDetector: FaceDetector
    private lateinit var gpuImage: GPUImage
    private var retouchIntensity: Float = 0.5f

    companion object {
        private const val TAG = "CameraXApp"
        private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"
        private const val REQUEST_CODE_PERMISSIONS = 10
        private val REQUIRED_PERMISSIONS =
            mutableListOf(
                CAMERA,
                android.Manifest.permission.RECORD_AUDIO
            ).apply {
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                    add(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                }
            }.toTypedArray()
    }

    private var view1: View? = null
    override fun getView(): View {
        if (view1 != null) {
            return view1!!
        }
        view1 = LayoutInflater.from(context).inflate(R.layout.item_camera, null, false)
        channel.setMethodCallHandler(this)
        viewFinder = view1!!.findViewById(R.id.viewFinder)

        if (allPermissionsGranted()) {
            startCamera()
        } else {
            ActivityCompat.requestPermissions(
                context!!, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS
            )
        }
        return view1!!
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
    }

    override fun onFlutterViewDetached() {
        super.onFlutterViewDetached()
    }

    private fun takePhoto() {}

    @SuppressLint("RestrictedApi")
    private fun captureVideo() {
        val currentVideoCapture = videoCapture ?: return

        val outputFile = getOutputMediaFile()
        val outputOptions = FileOutputOptions.Builder(outputFile).build()

        recording = currentVideoCapture.output
            .prepareRecording(context!!, outputOptions)
            .apply {
                if (PermissionChecker.checkSelfPermission(
                        context,
                        android.Manifest.permission.RECORD_AUDIO
                    ) == PermissionChecker.PERMISSION_GRANTED
                ) {
                    withAudioEnabled()
                }
            }
            .start(ContextCompat.getMainExecutor(context)) { event ->
                when (event) {
                    is VideoRecordEvent.Start -> {
                        Log.d(TAG, "Video capture started")
                    }
                    is VideoRecordEvent.Finalize -> {
                        if (!event.hasError()) {
                            channel.invokeMethod("url_path", outputFile.absolutePath)
                            Log.d(TAG, "Video capture succeeded: ${event.outputResults.outputUri}")
                        } else {
                            recording?.close()
                            recording = null
                            Log.e(TAG, "Video capture failed: ${event.error}")
                        }
                    }
                }
            }
    }

    private fun getOutputMediaFile(): File {
        val state: String = Environment.getExternalStorageState()
        val filesDir: File? = if (Environment.MEDIA_MOUNTED == state) {
            context?.getExternalFilesDir(null)
        } else {
            context?.filesDir
        }
        val file = File(filesDir, "finalvideo.mp4")
        if (!file.exists()) {
            file.createNewFile()
        }
        return file
    }

    var isFlashOn: Boolean = false
    var isFrontCamera: Boolean = false

    @SuppressLint("ClickableViewAccessibility")
    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context!!)
        viewFinder.implementationMode = PreviewView.ImplementationMode.COMPATIBLE

        val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

        // Preview
        val preview = Preview.Builder()
            .build()
            .also {
                it.setSurfaceProvider(viewFinder.surfaceProvider)
            }

        // Select back camera as a default
        val cameraSelector = if (isFrontCamera) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }

        // Image analyzer for retouch effects
        imageAnalyzer = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also { analysis ->
                analysis.setAnalyzer(cameraExecutor) { image ->
                    if (isRetouchEnabled) {
                        applyRetouchEffect(image)
                    } else {
                        image.close()
                    }
                }
            }

        try {
            // Unbind use cases before rebinding
            cameraProvider.unbindAll()

            // Bind use cases to camera
            val qualitySelector = QualitySelector.fromOrderedList(
                listOf(Quality.HD, Quality.SD),
                FallbackStrategy.lowerQualityOrHigherThan(Quality.SD)
            )

            val recorder = Recorder.Builder()
                .setQualitySelector(qualitySelector)
                .build()
            
            videoCapture = VideoCapture.withOutput(recorder)

            val rotation = context.windowManager.defaultDisplay.rotation
            val viewPort = ViewPort.Builder(
                Rational(context.window.decorView.width, context.window.decorView.height),
                rotation
            ).build()

            val useCaseGroup = UseCaseGroup.Builder()
                .addUseCase(preview)
                .addUseCase(videoCapture!!)
                .apply {
                    if (isRetouchEnabled) {
                        addUseCase(imageAnalyzer!!)
                    }
                }
                .setViewPort(viewPort)
                .build()

            camera = cameraProvider.bindToLifecycle(
                object : LifecycleOwner {
                    override val lifecycle: Lifecycle
                        get() = object : Lifecycle() {
                            override val currentState: State
                                get() = State.STARTED

                            override fun addObserver(observer: LifecycleObserver) {}
                            override fun removeObserver(observer: LifecycleObserver) {}
                        }
                },
                cameraSelector,
                useCaseGroup
            )

            viewFinder.setOnTouchListener { _, motionEvent ->
                val meteringPoint = viewFinder.meteringPointFactory
                    .createPoint(motionEvent.x, motionEvent.y)
                val action = FocusMeteringAction.Builder(meteringPoint)
                    .addPoint(meteringPoint, FLAG_AF or FLAG_AE)
                    .setAutoCancelDuration(3, TimeUnit.SECONDS)
                    .build()

                camera.cameraControl.startFocusAndMetering(action)
                true
            }

        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    private fun setupFaceDetector() {
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .build()
        
        faceDetector = FaceDetection.getClient(options)
    }

    private fun setupGPUImage() {
        gpuImage = GPUImage(context)
        setupRetouchFilters()
    }

    private fun setupRetouchFilters() {
        val filterGroup = GPUImageFilterGroup()
        
        // Basic smoothing filter
        val smoothFilter = GPUImageGaussianBlurFilter()
        smoothFilter.setBlurSize(retouchIntensity * 2.0f)
        filterGroup.addFilter(smoothFilter)
        
        // Brightness adjustment
        val brightnessFilter = GPUImageBrightnessFilter()
        brightnessFilter.setBrightness(0.1f)
        filterGroup.addFilter(brightnessFilter)
        
        // Sharpen for details
        val sharpenFilter = GPUImageSharpenFilter()
        sharpenFilter.setSharpness(0.5f)
        filterGroup.addFilter(sharpenFilter)
        
        gpuImage.setFilter(filterGroup)
    }

    private fun applyRetouchEffect(image: ImageProxy) {
        if (!isRetouchEnabled) {
            image.close()
            return
        }

        try {
            // Initialize face detector if needed
            if (!::faceDetector.isInitialized) {
                setupFaceDetector()
            }

            val bitmap = image.toBitmap()
            
            // Detect faces
            val inputImage = InputImage.fromBitmap(bitmap, image.imageInfo.rotationDegrees)
            
            faceDetector.process(inputImage)
                .addOnSuccessListener { faces ->
                    try {
                        if (faces.isNotEmpty()) {
                            // Apply retouch effects
                            val retouchedBitmap = applyRetouchFilters(bitmap, faces)
                            
                            // Update preview with retouched image
                            updatePreview(retouchedBitmap)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error applying retouch filters: ${e.message}")
                    }
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Face detection failed: ${e.message}")
                }
                .addOnCompleteListener {
                    try {
                        image.close()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error closing image: ${e.message}")
                    }
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error in applyRetouchEffect: ${e.message}")
            try {
                image.close()
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    private fun applyRetouchFilters(originalBitmap: Bitmap, faces: List<Face>): Bitmap {
        gpuImage.setImage(originalBitmap)
        
        // Apply base filters (skin smoothing, brightness, etc.)
        val resultBitmap = gpuImage.bitmapWithFilterApplied
        
        // Create a mutable copy for face-specific retouching
        val mutableBitmap = resultBitmap.copy(Bitmap.Config.ARGB_8888, true)
        
        // For each detected face, apply specific retouching
        faces.forEach { face ->
            applyFaceSpecificRetouching(mutableBitmap, face)
        }
        
        return mutableBitmap
    }

    private fun applyFaceSpecificRetouching(bitmap: Bitmap, face: Face) {
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        
        // Face slimming
        face.getContour(FaceContour.FACE)?.let { contour ->
            val points = contour.points
            if (points.isNotEmpty()) {
                // Apply face slimming transformation
                val path = Path()
                points.forEachIndexed { index, point ->
                    if (index == 0) path.moveTo(point.x, point.y)
                    else path.lineTo(point.x, point.y)
                }
                path.close()
                
                // Apply slight pinch effect for face slimming
                val matrix = Matrix()
                matrix.setScale(0.95f, 1f, face.boundingBox.centerX().toFloat(), face.boundingBox.centerY().toFloat())
                path.transform(matrix)
                
                canvas.drawPath(path, paint)
            }
        }
        
        // Eye enlargement
        face.getLandmark(FaceLandmark.LEFT_EYE)?.let { leftEye ->
            enlargeEye(canvas, leftEye.position, paint)
        }
        face.getLandmark(FaceLandmark.RIGHT_EYE)?.let { rightEye ->
            enlargeEye(canvas, rightEye.position, paint)
        }
    }

    private fun enlargeEye(canvas: Canvas, center: PointF, paint: Paint) {
        val radius = 20f
        val enlargeFactor = 1.2f
        
        paint.shader = RadialGradient(
            center.x, center.y, radius,
            intArrayOf(Color.TRANSPARENT, Color.BLACK),
            floatArrayOf(0f, 1f),
            Shader.TileMode.CLAMP
        )
        
        canvas.drawCircle(center.x, center.y, radius * enlargeFactor, paint)
    }

    private fun updatePreview(bitmap: Bitmap) {
        // Update preview using a TextureView or SurfaceView backing the PreviewView
        viewFinder.post {
            try {
                when (val view = viewFinder.getChildAt(0)) {
                    is TextureView -> {
                        // Update TextureView
                        val canvas = view.lockCanvas()
                        canvas?.let {
                            it.drawBitmap(bitmap, 0f, 0f, null)
                            view.unlockCanvasAndPost(it)
                        }
                    }
                    is SurfaceView -> {
                        // Update SurfaceView
                        val holder = view.holder
                        val canvas = holder.lockCanvas()
                        canvas?.let {
                            it.drawBitmap(bitmap, 0f, 0f, null)
                            holder.unlockCanvasAndPost(it)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("CameraXView", "Error updating preview: ${e.message}")
            }
        }
    }

    private fun ImageProxy.toBitmap(): Bitmap {
        val yBuffer = planes[0].buffer // Y
        val uBuffer = planes[1].buffer // U
        val vBuffer = planes[2].buffer // V

        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()

        val nv21 = ByteArray(ySize + uSize + vSize)

        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
        val imageBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(context!!, it) == PackageManager.PERMISSION_GRANTED
    }

    override fun dispose() {
        cameraExecutor.shutdown()
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context!!)
        val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
        cameraProvider.unbindAll()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                captureVideo()
            }
            "pause" -> {
                recording?.pause()
            }
            "resume" -> {
                recording?.resume()
            }
            "stop" -> {
                recording?.stop()
                recording = null
            }
            "toggle" -> {
                isFrontCamera = !isFrontCamera
                startCamera()
            }
            "toggle_retouch" -> {
                isRetouchEnabled = !isRetouchEnabled
                if (isRetouchEnabled) {
                    retouchIntensity = call.argument<Double>("intensity")?.toFloat() ?: 0.5f
                    
                    // Initialize required components for retouch
                    if (!::gpuImage.isInitialized) {
                        setupGPUImage()
                    } else {
                        setupRetouchFilters()
                    }
                    
                    if (!::faceDetector.isInitialized) {
                        setupFaceDetector()
                    }
                }
                startCamera()
            }
            "flash" -> {
                isFlashOn = !isFlashOn
                camera.cameraControl.enableTorch(isFlashOn)
            }
        }
    }
}
