<?php

// app/Http/Controllers/API/AppVersionController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\AppVersion;
use Illuminate\Support\Facades\Log;
use App\Admin;

class AppVersionController extends Controller
{
    public function getVersion()
    {
        try {
            // Verify API request headers
            $headers = request()->headers->all();
            $verify_request_base = Admin::verify_request_base($headers);

            if (isset($verify_request_base['status']) && $verify_request_base['status'] == 401) {
                return response()->json([
                    'status' => false,
                    'message' => "Unauthorized Access!"
                ], 401);
            }

            // Get version info
            $version = AppVersion::latest()->first();

            if (!$version) {
                return response()->json([
                    'status' => false,
                    'message' => 'Version information not found',
                    'data' => null
                ], 404);
            }

            return response()->json(['status' => 200, 'message' => 'Version info retrieved successfully','data' => $version]);


            // return response()->json([
            //     'status' => true,
            //     'message' => 'Version info retrieved successfully',
            //     'data' => $version
            // ], 200)->header('Content-Type', 'application/json');

        } catch (\Exception $e) {
            Log::error('Error in getVersion: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Error retrieving version info',
                'error' => $e->getMessage()
            ], 500)->header('Content-Type', 'application/json');
        }
    }
}