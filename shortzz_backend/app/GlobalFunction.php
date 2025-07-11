<?php

namespace App;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Util\GlobalState;

class GlobalFunction extends Model
{
    use HasFactory;

    public static function createMediaUrl($media)
    {
        $url = env('ITEM_BASE_URL') . $media;
        return $url;
    }

    public static function uploadFilToS3($file)
    {
        try {
            // Set maximum execution time for large uploads
            set_time_limit(300); // 5 minutes
            
        $s3 = Storage::disk('s3');
        $fileName = time() . $file->getClientOriginalName();
            $fileName = str_replace(array(' ', ':', '(', ')', ',', '#', '&'), '_', $fileName);
        $destinationPath = env('DEFAULT_IMAGE_PATH');
        $filePath = $destinationPath . $fileName;
            
            // Log file upload attempt
            $fileSize = $file->getSize() / 1024 / 1024; // Convert to MB
            Log::info('S3 Upload Attempt', [
                'file_name' => $fileName,
                'file_size_mb' => round($fileSize, 2),
                'destination' => $filePath
            ]);
            
            // Check file size before upload
            if ($fileSize > 100) { // 100MB limit
                Log::error('S3 Upload Failed: File too large', [
                    'file_name' => $fileName,
                    'file_size_mb' => round($fileSize, 2)
                ]);
                throw new \Exception('File size exceeds 100MB limit');
            }
            
            // Upload with streaming for large files
            $result = $s3->put($filePath, fopen($file->getRealPath(), 'r'), 'public-read');
            
            if ($result) {
                Log::info('S3 Upload Success', [
                    'file_name' => $fileName,
                    'file_size_mb' => round($fileSize, 2)
                ]);
        return $fileName;
            } else {
                Log::error('S3 Upload Failed', [
                    'file_name' => $fileName,
                    'error' => 'Unknown S3 error'
                ]);
                throw new \Exception('Failed to upload file to S3');
            }
            
        } catch (\Exception $e) {
            Log::error('S3 Upload Exception', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    public static function cleanString($string)
    {

        return  str_replace(array('<', '>', '{', '}', '[', ']', '`'), '', $string);
    }

    public static function generateRandomString($length)
    {
        $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $charactersLength = strlen($characters);
        $randomString = '';
        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[rand(0, $charactersLength - 1)];
        }
        return $randomString;
    }
}
