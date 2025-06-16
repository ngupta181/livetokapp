<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Log;
use Exception;

class ApiLogger
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle($request, Closure $next)
    {
        try {
            // Generate a unique request ID
            $requestId = uniqid('req_');
            
            // Log using both default and API channels
            $requestData = [
                'request_id' => $requestId,
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'headers' => $this->sanitizeHeaders($request->headers->all()),
                'body' => $this->sanitizeData($request->all()),
                'ip' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'timestamp' => now()->toDateTimeString(),
            ];

            // Log to both channels to ensure it's working
            Log::info("API Request [$requestId]", $requestData);
            Log::channel('api')->info("API Request [$requestId]", $requestData);

            // Write directly to file as a fallback
            $this->writeToFile("API Request [$requestId]: " . json_encode($requestData));

            $response = $next($request);

            // Get response content
            $content = $response->getContent();
            
            // Check if response is HTML/script
            $isHtml = strpos($content, '<script>') !== false || 
                     strpos($content, '<html>') !== false || 
                     strpos($content, '<!DOCTYPE') !== false;
            
            $responseData = [
                'request_id' => $requestId,
                'status_code' => $response->getStatusCode(),
                'headers' => $this->sanitizeHeaders($response->headers->all()),
                'content_type' => $response->headers->get('content-type'),
                'is_html' => $isHtml,
                'content' => $isHtml ? $content : json_decode($content, true),
                'response_time' => microtime(true) - LARAVEL_START,
                'timestamp' => now()->toDateTimeString(),
            ];

            $logLevel = $isHtml ? 'error' : 'info';

            // Log to both channels
            Log::$logLevel("API Response [$requestId]", $responseData);
            Log::channel('api')->$logLevel("API Response [$requestId]", $responseData);

            // Write directly to file as a fallback
            $this->writeToFile("API Response [$requestId]: " . json_encode($responseData));

            if ($isHtml) {
                $debugData = [
                    'request_id' => $requestId,
                    'session_id' => session()->getId(),
                    'session_data' => session()->all(),
                    'cookies' => $request->cookies->all(),
                    'route' => $request->route() ? [
                        'name' => $request->route()->getName(),
                        'action' => $request->route()->getActionName(),
                        'middleware' => $request->route()->middleware(),
                    ] : null,
                    'timestamp' => now()->toDateTimeString(),
                ];

                Log::error("HTML Response Debug [$requestId]", $debugData);
                Log::channel('api')->error("HTML Response Debug [$requestId]", $debugData);
                $this->writeToFile("HTML Debug [$requestId]: " . json_encode($debugData));
            }

            return $response;

        } catch (Exception $e) {
            // Log any errors in the middleware itself
            $errorData = [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ];
            
            Log::error("ApiLogger Error", $errorData);
            Log::channel('api')->error("ApiLogger Error", $errorData);
            $this->writeToFile("ApiLogger Error: " . json_encode($errorData));

            return $next($request);
        }
    }

    private function sanitizeHeaders(array $headers): array
    {
        // Remove sensitive information from headers
        $sensitiveHeaders = ['authorization', 'cookie', 'x-xsrf-token'];
        return array_filter($headers, function($key) use ($sensitiveHeaders) {
            return !in_array(strtolower($key), $sensitiveHeaders);
        }, ARRAY_FILTER_USE_KEY);
    }

    private function sanitizeData(array $data): array
    {
        // Remove sensitive information from request data
        $sensitiveFields = ['password', 'token', 'secret'];
        return array_filter($data, function($key) use ($sensitiveFields) {
            return !in_array(strtolower($key), $sensitiveFields);
        }, ARRAY_FILTER_USE_KEY);
    }

    private function writeToFile(string $message): void
    {
        try {
            $logFile = storage_path('logs/api/direct_api.log');
            $directory = dirname($logFile);
            
            if (!is_dir($directory)) {
                mkdir($directory, 0777, true);
            }
            
            file_put_contents(
                $logFile,
                date('[Y-m-d H:i:s] ') . $message . PHP_EOL,
                FILE_APPEND
            );
        } catch (Exception $e) {
            // If even this fails, we'll try writing to the PHP error log
            error_log("Failed to write to API log file: " . $e->getMessage());
        }
    }
} 