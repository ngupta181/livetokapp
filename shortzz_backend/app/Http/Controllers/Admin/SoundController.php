<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Redirect;
use URL;
use Session;
use Storage;
use App\Admin;
use App\GlobalFunction;
use App\Sound;
use App\SoundCategory;
use App\GlobalSettings;
use Carbon\Carbon;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SoundController extends Controller
{
	/**
	 * View Shazam sync dashboard
	 *
	 * @return \Illuminate\View\View
	 */
	public function viewShazamSync()
	{
		$settings = GlobalSettings::first();
		$last_sync = $settings->shazam_last_sync ? Carbon::parse($settings->shazam_last_sync)->diffForHumans() : 'Never';
		$shazam_tracks = Sound::where('is_deleted', 0)->where('added_by', 'shazam')->count();
		
		return view('admin.sound.shazam_sync')
			->with('last_sync', $last_sync)
			->with('shazam_tracks', $shazam_tracks)
			->with('settings', $settings);
	}



public function fetchShazamTrending(Request $request)
{
    try {
        $settings = GlobalSettings::first();

        if (empty($settings->shazam_api_key)) {
            return response()->json([
                'success' => 0,
                'message' => 'Shazam API key not configured. Please update settings first.'
            ]);
        }

        // Use a much higher limit to get all available new tracks
        $limit = $settings->shazam_tracks_limit ?? 200; // Increased from 50 to 200
        $client = new \GuzzleHttp\Client();
        $tracks = [];
        
        // Set explicit content-type headers for proper JSON responses
        $headers = [
            'X-RapidAPI-Key' => $settings->shazam_api_key,
            'X-RapidAPI-Host' => 'shazam.p.rapidapi.com',
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
        ];
        
        // Try multiple endpoints to ensure we get data
        $endpoints = [
            // First try US Top 200 chart specifically
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'ip-country-chart-US',
                    'pageSize' => 200,  // Request full 200 tracks
                    'startFrom' => 0
                ]
            ],
            // Try specific city charts in the US
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'city-charts-US-2450022', // New York
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'city-charts-US-2487956', // Los Angeles
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            // Add India charts with high priority
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-IN',
                    'listId' => 'ip-country-chart-IN', // India charts
                    'pageSize' => 200, // Request full 200 tracks for India
                    'startFrom' => 0
                ]
            ],
            // Try specific city charts in India
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-IN',
                    'listId' => 'city-charts-IN-1275339', // Mumbai
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-IN',
                    'listId' => 'city-charts-IN-1273294', // Delhi
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            // Try with different countries as fallback
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'ip-country-chart-GB', // UK charts
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            // Then try world charts with different structure
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            // Try genre-specific charts
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'genre-global-chart-1', // Pop
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/track',
                'query' => [
                    'locale' => 'en-US',
                    'listId' => 'genre-global-chart-2', // Hip-Hop/Rap
                    'pageSize' => $limit,
                    'startFrom' => 0
                ]
            ],
            // Try search endpoint as fallback
            [
                'url' => 'https://shazam.p.rapidapi.com/search',
                'query' => [
                    'term' => 'popular music',
                    'locale' => 'en-US',
                    'limit' => $limit
                ]
            ],
            [
                'url' => 'https://shazam.p.rapidapi.com/search',
                'query' => [
                    'term' => 'trending',
                    'locale' => 'en-US',
                    'limit' => $limit
                ]
            ],
            // Last resort try charts list
            [
                'url' => 'https://shazam.p.rapidapi.com/charts/list',
                'query' => [
                    'locale' => 'en-US'
                ]
            ]
        ];
        
        $successfulEndpoints = [];
        $allTracks = [];
        
        foreach ($endpoints as $endpoint) {
            try {
                \Log::info('Trying Shazam endpoint: ' . $endpoint['url'] . ' with params: ' . json_encode($endpoint['query']));
                
                $response = $client->get($endpoint['url'], [
                    'headers' => $headers,
                    'query' => $endpoint['query'],
                    'http_errors' => false // Don't throw exceptions on 4xx/5xx
                ]);
                
                $statusCode = $response->getStatusCode();
                \Log::info('Response status code: ' . $statusCode);
                
                // Handle 204 No Content or other non-200 responses
                if ($statusCode !== 200) {
                    \Log::warning('Non-success status code (' . $statusCode . ') from endpoint: ' . $endpoint['url']);
                    continue;
                }
                
                $responseBody = (string) $response->getBody();
                
                // Verify we got a valid JSON response
                if (empty($responseBody) || !$this->isValidJson($responseBody)) {
                    \Log::warning('Invalid or empty JSON from endpoint: ' . $endpoint['url']);
                    continue;
                }
                
                $data = json_decode($responseBody, true);
                $endpointTracks = [];
                
                // Handle different response structures based on endpoint
                if ($endpoint['url'] === 'https://shazam.p.rapidapi.com/charts/track') {
                    if (isset($data['tracks']) && is_array($data['tracks'])) {
                        $endpointTracks = $data['tracks'];
                        $successfulEndpoints[] = $endpoint['url'] . ' (tracks) - ' . count($endpointTracks) . ' tracks';
                    }
                } else if ($endpoint['url'] === 'https://shazam.p.rapidapi.com/search') {
                    if (isset($data['tracks']) && isset($data['tracks']['hits'])) {
                        // Extract tracks from search results
                        $searchTracks = [];
                        foreach ($data['tracks']['hits'] as $hit) {
                            if (isset($hit['track'])) {
                                $searchTracks[] = $hit['track'];
                            }
                        }
                        if (!empty($searchTracks)) {
                            $endpointTracks = $searchTracks;
                            $successfulEndpoints[] = $endpoint['url'] . ' (search hits) - ' . count($endpointTracks) . ' tracks';
                        }
                    }
                } else if ($endpoint['url'] === 'https://shazam.p.rapidapi.com/charts/list') {
                    // Try to get tracks from multiple charts
                    if (isset($data['charts']) && is_array($data['charts'])) {
                        foreach ($data['charts'] as $chart) {
                            if (isset($chart['tracks']) && is_array($chart['tracks'])) {
                                $endpointTracks = array_merge($endpointTracks, $chart['tracks']);
                            }
                        }
                        if (!empty($endpointTracks)) {
                            $successfulEndpoints[] = $endpoint['url'] . ' (chart list) - ' . count($endpointTracks) . ' tracks';
                        }
                    }
                }
                
                // Add to our collection of all tracks, using key to avoid duplicates
                if (!empty($endpointTracks)) {
                    foreach ($endpointTracks as $track) {
                        if (isset($track['key'])) {
                            $allTracks[$track['key']] = $track;
                        }
                    }
                }
                
            } catch (\Exception $e) {
                \Log::warning('Error with endpoint ' . $endpoint['url'] . ': ' . $e->getMessage());
                continue;
            }
        }
        
        // Convert back to indexed array after removing duplicates
        $tracks = array_values($allTracks);
        
        if (empty($tracks)) {
            return response()->json([
                'success' => 0,
                'message' => 'Could not retrieve tracks from any Shazam API endpoint.'
            ])->header('Content-Type', 'application/json');
        }
        
        \Log::info('Successfully fetched ' . count($tracks) . ' total unique tracks from ' . count($successfulEndpoints) . ' endpoints: ' . implode(', ', $successfulEndpoints));
        
        // Filter tracks to only include those with valid playable URIs
        $filtered = collect($tracks)->filter(function ($track) {
            $actions = $track['hub']['actions'] ?? [];
            foreach ($actions as $action) {
                if (
                    in_array($action['type'], ['uri', 'applemusicplay']) &&
                    !empty($action['uri'])
                ) {
                    return true;
                }
            }
            return false;
        })->values();

        return response()->json([
            'success' => 1,
            'tracks' => $filtered
        ])->header('Content-Type', 'application/json');

    } catch (\Exception $e) {
        \Log::error('Shazam API error: ' . $e->getMessage());
        return response()->json([
            'success' => 0,
            'message' => 'Something went wrong: ' . $e->getMessage()
        ])->header('Content-Type', 'application/json');
    }
}




	/**
	 * Get tracks from Shazam API
	 * 
	 * @param int $limit
	 * @return array
	 */
	private function getTracksFromShazamAPI($limit = 50)
	{
		$settings = GlobalSettings::first();
		$client = new Client();
		
		try {
			// Log the request details for debugging
			Log::info('Shazam API request details: Host=' . $settings->shazam_api_host . ', Endpoint=/charts/track' . 
				', Query params: locale=en-US, pageSize=' . $limit . ', startFrom=0');
			
			// Make sure we have valid API credentials before attempting the call
			if (empty($settings->shazam_api_key) || empty($settings->shazam_api_host)) {
				throw new \Exception('Missing API credentials. Please configure Shazam API key and host in settings.');
			}
			
			// Try a simpler endpoint first to verify API access
			if ($this->shouldTestApiConnection()) {
				$this->testApiConnection($settings, $client);
			}
			
			// Since the test endpoint was successful, try first with the /charts/track endpoint with the updated parameters
			try {
				$response = $client->request('GET', 'https://' . $settings->shazam_api_host . '/charts/track', [
					'query' => [
						'locale' => 'en-US',
						'pageSize' => $limit,
						'startFrom' => 0
					],
					'headers' => [
						'X-RapidAPI-Key' => $settings->shazam_api_key,
						'X-RapidAPI-Host' => $settings->shazam_api_host,
						'Accept' => 'application/json'
					],
					'timeout' => 30,
					'connect_timeout' => 10,
					'verify' => false // Disable SSL verification as it worked in the test
				]);
			} catch (\Exception $e) {
				// If the first attempt fails, try with the /charts/list endpoint which is also supported
				Log::warning('First attempt failed, trying alternative endpoint: ' . $e->getMessage());
				
				$response = $client->request('GET', 'https://' . $settings->shazam_api_host . '/charts/list', [
					'headers' => [
						'X-RapidAPI-Key' => $settings->shazam_api_key,
						'X-RapidAPI-Host' => $settings->shazam_api_host,
						'Accept' => 'application/json'
					],
					'timeout' => 30,
					'connect_timeout' => 10,
					'verify' => false // Disable SSL verification as it worked in the test
				]);
			}
			
			$responseBody = $response->getBody()->getContents();
			
			// Check if response is empty
			if (empty(trim($responseBody))) {
				Log::error('Shazam API returned empty response. Status code: ' . $response->getStatusCode());
				// Log request details for debugging
				Log::error('Shazam API request details: Host=' . $settings->shazam_api_host . ', Key=' . substr($settings->shazam_api_key, 0, 5) . '...');
				throw new \Exception('API returned empty response. This could indicate an invalid API key, expired subscription, or network issue.');
			}
			
			// Log the actual response for debugging
			Log::info('Shazam API raw response: ' . substr($responseBody, 0, 1000));
			
			// Check if response is valid JSON
			if (!$this->isValidJson($responseBody)) {
				Log::error('Shazam API returned invalid JSON response: ' . substr($responseBody, 0, 500));
				throw new \Exception('API returned invalid JSON response. Check logs for details.');
			}
			
			$data = json_decode($responseBody, true);
			$tracks = [];
			
			// Handle different response formats based on which endpoint was used
			if (isset($data['tracks']) && is_array($data['tracks'])) {
				// Format for /charts/track endpoint
				$tracks = $data['tracks'];
			} elseif (isset($data['charts']) && is_array($data['charts'])) {
				// Format for /charts/list endpoint, which has a different structure
				// Find the first chart that has tracks
				foreach ($data['charts'] as $chart) {
					if (isset($chart['tracks']) && is_array($chart['tracks'])) {
						$tracks = $chart['tracks'];
						break;
					}
				}
			} elseif (isset($data['tracks']['hits']) && is_array($data['tracks']['hits'])) {
				// Format for /search endpoint as a last resort
				$tracks = array_map(function($hit) {
					return $hit['track'];
				}, $data['tracks']['hits']);
			}
			
			if (empty($tracks)) {
				Log::warning('Shazam API returned no tracks or unrecognized format. Response: ' . json_encode(array_keys($data)));
				return [];
			}
			
			Log::info('Successfully extracted ' . count($tracks) . ' tracks from Shazam API');
			return $tracks;
			
		} catch (RequestException $e) {
			$errorMessage = $e->getMessage();
			$statusCode = $e->getCode();
			
			// Get response body if available for better debugging
			if ($e->hasResponse()) {
				$errorBody = $e->getResponse()->getBody()->getContents();
				Log::error('Shazam API error: Status ' . $statusCode . ', Message: ' . $errorMessage . ', Response: ' . $errorBody);
			} else {
				Log::error('Shazam API connection error: ' . $errorMessage);
			}
			
			throw new \Exception('Failed to fetch tracks from Shazam: ' . $errorMessage);
		} catch (\Exception $e) {
			Log::error('Unexpected error when fetching from Shazam API: ' . $e->getMessage());
			throw new \Exception('Unexpected error when fetching tracks: ' . $e->getMessage());
		}
	}
	
	/**
	 * Check if a string is valid JSON
	 *
	 * @param string $string
	 * @return bool
	 */
	private function isValidJson($string) {
		json_decode($string);
		return json_last_error() === JSON_ERROR_NONE;
	}

	/**
	 * Helper method to ensure proper JSON response
	 * 
	 * @param array $data The data to return as JSON
	 * @return \Illuminate\Http\JsonResponse
	 */
	protected function jsonResponse($data)
	{
		return response()->json($data)
			->header('Content-Type', 'application/json')
			->header('X-Content-Type-Options', 'nosniff');
	}

	/**
	 * Process and save tracks from Shazam to database
	 * 
	 * @param array $tracks
	 * @return array Statistics of processed tracks
	 */
	private function processAndSaveTracks($tracks)
	{
		$stats = [
			'added' => 0,
			'updated' => 0,
			'skipped' => 0
		];
		
		// Make sure we have a category for trending music
		$category = SoundCategory::firstOrCreate(
			['sound_category_name' => 'Trending'],
			[
				'is_deleted' => 0,
				'sound_category_profile' => 'Trending music from Shazam API'
			]
		);
		
		// Create temporary directory for downloads
		$tempPath = storage_path('app/temp/shazam/');
		if (!File::isDirectory($tempPath)) {
			File::makeDirectory($tempPath, 0777, true);
		}
		
		foreach ($tracks as $track) {
			try {
				// Extract track information
				$title = $track['title'] ?? '';
				$artist = $track['subtitle'] ?? '';
				$imageUrl = $track['images']['coverart'] ?? null;
				$previewUrl = $track['hub']['actions'][1]['uri'] ?? null;
				$shazamId = $track['key'] ?? null;
				
				if (empty($title) || empty($shazamId) || empty($previewUrl)) {
					$stats['skipped']++;
					continue;
				}
				
				// Check if track exists by Shazam ID
				$existingSound = Sound::where('shazam_id', $shazamId)->first();
				
				// Define file paths
				$soundFileName = null;
				$imageFileName = null;
				
				// Only download and upload files if they don't exist or this is a new track
				if (!$existingSound || empty($existingSound->sound)) {
					if ($previewUrl) {
						// Download to temp location
						$tempSoundFile = $tempPath . 'shazam_' . $shazamId . '.mp3';
						$audioContents = file_get_contents($previewUrl);
						File::put($tempSoundFile, $audioContents);
						
						// Upload to S3
						if (File::exists($tempSoundFile)) {
							$soundFile = new \Illuminate\Http\UploadedFile(
								$tempSoundFile,
								'shazam_' . $shazamId . '.mp3',
								'audio/mpeg',
								null,
								true
							);
							$soundFileName = GlobalFunction::uploadFilToS3($soundFile);
							
							// Clean up temp file
							File::delete($tempSoundFile);
						}
					}
				} else {
					$soundFileName = $existingSound->sound;
				}
				
				if (!$existingSound || empty($existingSound->sound_image)) {
					if ($imageUrl) {
						// Download to temp location
						$tempImageFile = $tempPath . 'shazam_' . $shazamId . '.jpg';
						$imageContents = file_get_contents($imageUrl);
						File::put($tempImageFile, $imageContents);
						
						// Upload to S3
						if (File::exists($tempImageFile)) {
							$imageFile = new \Illuminate\Http\UploadedFile(
								$tempImageFile,
								'shazam_' . $shazamId . '.jpg',
								'image/jpeg',
								null,
								true
							);
							$imageFileName = GlobalFunction::uploadFilToS3($imageFile);
							
							// Clean up temp file
							File::delete($tempImageFile);
						}
					}
				} else {
					$imageFileName = $existingSound->sound_image;
				}
				
				// Calculate audio duration
				$duration = 30; // Default duration for preview is usually 30 seconds
				
				$data = [
					'sound_category_id' => $category->sound_category_id,
					'sound_title' => $title,
					'singer' => $artist,
					'duration' => $duration,
					'added_by' => 'shazam',
					'shazam_id' => $shazamId,
					'is_deleted' => 0
				];
				
				// Only update file paths if we got new files
				if ($soundFileName) {
					$data['sound'] = $soundFileName;
				}
				
				if ($imageFileName) {
					$data['sound_image'] = $imageFileName;
				}
				
				if ($existingSound) {
					// Update existing track
					Sound::where('sound_id', $existingSound->sound_id)->update($data);
					$stats['updated']++;
				} else {
					// Add new track
					Sound::insert($data);
					$stats['added']++;
				}
				
			} catch (\Exception $e) {
				Log::error('Error processing track: ' . $e->getMessage());
				$stats['skipped']++;
				continue;
			}
		}
		
		// Clean up temp directory
		if (File::isDirectory($tempPath)) {
			File::deleteDirectory($tempPath);
		}
		
		return $stats;
	}

	/**
	 * Admin-facing API to manually trigger a sync
	 *
	 * @param Request $request
	 * @return \Illuminate\Http\JsonResponse
	 */
	public function syncShazamMusic(Request $request)
	{
	    try {
	        $response = $this->fetchShazamTrending($request);
	        $data = json_decode($response->getContent(), true);
	        if (isset($data['tracks']) && is_array($data['tracks'])) {
	            $tracks = $data['tracks'];
	            $processed = $this->processAndSaveTracks($tracks);
	            $settings = GlobalSettings::first();
	            $settings->shazam_last_sync = Carbon::now();
	            $settings->save();
	            
	            \Log::info('Shazam sync completed successfully: ' . $processed['added'] . ' new, ' . 
	                      $processed['updated'] . ' updated, ' . $processed['skipped'] . ' skipped');
	                      
	            return $this->jsonResponse([
	                'success' => 1,
	                'message' => 'Successfully synced ' . $processed['added'] . ' new tracks, updated ' . $processed['updated'] . ' tracks, and skipped ' . $processed['skipped'] . ' tracks.'
	            ]);
	        } else {
	            \Log::warning('No valid tracks found in Shazam API response');
	            return $this->jsonResponse([
	                'success' => 0,
	                'message' => 'No valid tracks found in API response.'
	            ]);
	        }
	    } catch (\Exception $e) {
	        \Log::error('Error syncing Shazam music: ' . $e->getMessage());
	        return $this->jsonResponse([
	            'success' => 0,
	            'message' => 'Error syncing music: ' . $e->getMessage()
	        ]);
	    }
	}
	
	/**
	 * Test connection to the Shazam API
	 *
	 * @param Request $request
	 * @return \Illuminate\Http\JsonResponse
	 */
	public function testShazamApiConnection(Request $request)
	{
		try {
			$settings = GlobalSettings::first();
			$client = new Client();
			
			// Test connection using a simpler endpoint
			$testResult = $this->testApiConnection($settings, $client, true);
			
			return response()->json([
				'success' => 1,
				'message' => 'Successfully connected to Shazam API',
				'data' => $testResult
			]);
			
		} catch (\Exception $e) {
			Log::error('Shazam API test connection error: ' . $e->getMessage());
			return response()->json([
				'success' => 0,
				'message' => 'Error connecting to Shazam API: ' . $e->getMessage()
			]);
		}
	}
	
	/**
	 * Test if API connection works
	 *
	 * @param GlobalSettings $settings
	 * @param Client $client
	 * @param bool $returnResponse
	 * @return bool|array
	 * @throws \Exception
	 */
	private function testApiConnection($settings, $client, $returnResponse = false)
	{
		try {
			// Try a simpler API endpoint to test connection
			$response = $client->request('GET', 'https://' . $settings->shazam_api_host . '/search', [
				'query' => [
					'term' => 'test',
					'limit' => 1
				],
				'headers' => [
					'X-RapidAPI-Key' => $settings->shazam_api_key,
					'X-RapidAPI-Host' => $settings->shazam_api_host,
					'Accept' => 'application/json'
				],
				'timeout' => 10,
				'connect_timeout' => 5,
				'verify' => false // Disable SSL verification for testing
			]);
			
			$responseBody = $response->getBody()->getContents();
			$statusCode = $response->getStatusCode();
			
			if ($statusCode !== 200) {
				throw new \Exception('API test failed with status code: ' . $statusCode);
			}
			
			if (empty(trim($responseBody))) {
				throw new \Exception('API test returned empty response');
			}
			
			if (!$this->isValidJson($responseBody)) {
				throw new \Exception('API test returned invalid JSON response');
			}
			
			Log::info('Shazam API test connection successful. Status: ' . $statusCode);
			
			if ($returnResponse) {
				return [
					'status_code' => $statusCode,
					'response_length' => strlen($responseBody),
					'is_valid_json' => true,
					'sample' => substr($responseBody, 0, 100) . '...'
				];
			}
			
			return true;
			
		} catch (\Exception $e) {
			Log::error('API test connection error: ' . $e->getMessage());
			if ($returnResponse) {
				throw $e;
			}
			return false;
		}
	}
	
	/**
	 * Determine if we should test API connection
	 *
	 * @return bool
	 */
	private function shouldTestApiConnection()
	{
		// Get last failed time from cache to avoid repeated tests
		$lastFailed = cache('shazam_api_last_failed');
		$now = time();
		
		// If no record of failure or it was more than 30 minutes ago
		return !$lastFailed || ($now - $lastFailed) > 1800;
	}

	public function viewListSound()
	{
		$total_sound = Sound::where('added_by', 'admin')->count();
		$sound_category_data = SoundCategory::where('is_deleted', 0)->orderBy('sound_category_id', 'DESC')->get();
		return view('admin.sound.sound_list')->with('total_sound', $total_sound)->with('sound_category_data', $sound_category_data);
	}

	public function addUpdateSound(Request $request)
	{
		$sound_id = $request->input('sound_id');
		$sound_category_id = $request->input('sound_category_id');
		$sound_title = $request->input('sound_title');
		$singer = $request->input('singer');
		$duration = $request->input('duration');

		if ($request->hasfile('sound')) {
			$file = $request->file('sound');
			$data['sound'] = GlobalFunction::uploadFilToS3($file);
		}

		if ($request->hasfile('sound_image')) {
			$file = $request->file('sound_image');
			$data['sound_image'] = GlobalFunction::uploadFilToS3($file);
		}

		$data['sound_category_id'] = $sound_category_id;
		$data['sound_title'] = $sound_title;
		$data['singer'] = $singer;
		$data['duration'] = $duration;
		$data['added_by'] = 'admin';

		if (!empty($sound_id)) {
			$result =  Sound::where('sound_id', $sound_id)->update($data);
			$msg = "Update";
			$response['flag'] = 2;
		} else {
			$result =  Sound::insert($data);
			$msg = "Add";
			$response['flag'] = 1;
		}
		$total_sound = Sound::count();
		if ($result) {
			$response['success'] = 1;
			$response['message'] = "Successfully " . $msg . " Sound";
			$response['total_sound'] = $total_sound;
		} else {
			$response['success'] = 0;
			$response['message'] = "Error While " . $msg . " Sound";
			$response['total_sound'] = 0;
		}
		echo json_encode($response);
	}

	public function getSoundByID(Request $request)
	{
		$sound_id = $request->input('sound_id');
		$data = Sound::select('tbl_sound.*', 'st.sound_category_id')->leftjoin('tbl_sound_category as st', 'tbl_sound.sound_category_id', 'st.sound_category_id')->where('tbl_sound.sound_id', $sound_id)->first();

		$response['success'] = 1;
		$response['sound_category_id'] = $data->sound_category_id;
		$response['sound_title'] = $data->sound_title;
		$response['sound'] = url(env('DEFAULT_IMAGE_URL') . $data->sound);
		$response['sound_image'] = url(env('DEFAULT_IMAGE_URL') . $data->sound_image);
		$response['singer'] = $data->singer;
		$response['duration'] = $data->duration;
		echo json_encode($response);
	}

	public function deleteSound(Request $request)
	{

		$sound_id = $request->input('sound_id');
		$sound =  Sound::where('sound_id', $sound_id)->first();
		$sound->is_deleted = 1;
		$result = $sound->save();

		$total_sound = Sound::where('is_deleted', 0)->where('added_by', 'admin')->count();

		if ($result) {
			$response['success'] = 1;
			$response['total_sound'] = $total_sound;
		} else {
			$response['success'] = 0;
			$response['total_sound'] = 0;
		}
		echo json_encode($response);
	}

	public function viewListSoundCategory()
	{
		$total_sound_category = SoundCategory::count();
		return view('admin.sound.sound_category_list')->with('total_sound_category', $total_sound_category);
	}

	public function addUpdateSoundCategory(Request $request)
	{
		$sound_category_id = $request->input('sound_category_id');
		$sound_category_name = $request->input('sound_category_name');

		if ($request->hasfile('sound_category_profile')) {
			$file = $request->file('sound_category_profile');
			$data['sound_category_profile'] = GlobalFunction::uploadFilToS3($file);
		}

		$data['sound_category_name'] = $sound_category_name;

		if (!empty($sound_category_id)) {
			$result =  SoundCategory::where('sound_category_id', $sound_category_id)->update($data);
			$msg = "Update";
			$response['flag'] = 2;
		} else {
			$result =  SoundCategory::insert($data);
			$msg = "Add";
			$response['flag'] = 1;
		}
		$total_sound_category = SoundCategory::count();
		if ($result) {
			$response['success'] = 1;
			$response['message'] = "Successfully " . $msg . " Sound";
			$response['total_sound_category'] = $total_sound_category;
		} else {
			$response['success'] = 0;
			$response['message'] = "Error While " . $msg . " Sound";
			$response['total_sound_category'] = 0;
		}
		echo json_encode($response);
	}

	public function deleteSoundCategory(Request $request)
	{
		$sound_category_id = $request->input('sound_category_id');
		$cat =  SoundCategory::where('sound_category_id', $sound_category_id)->first();

        Sound::where('sound_category_id', $sound_category_id)->update(['is_deleted'=> 1]);

		$cat->is_deleted = 1;
		$result = $cat->save();


		$total_sound_category = SoundCategory::where('is_deleted', 0)->count();

		if ($result) {
			$response['success'] = 1;
			$response['total_sound_category'] = $total_sound_category;
		} else {
			$response['success'] = 0;
			$response['total_sound_category'] = 0;
		}
		echo json_encode($response);
	}

	public function showSoundList(Request $request)
	{

		$columns = array(
			0 => 'sound_id',
			1 => 'sound',
			2 => 'sound_title',
			3 => 'sound_title',
			4 => 'duration',
			5 => 'singer',
		);

		$limit = $request->input('length');
		$start = $request->input('start');
		$order = $columns[$request->input('order.0.column')];
		$dir = $request->input('order.0.dir');

		if (empty($request->input('search.value'))) {

			$SoundData = Sound::where('tbl_sound.is_deleted', 0)
				->whereIn('added_by', ['admin', 'shazam']) // Include both admin and Shazam tracks
				->select('tbl_sound.*', 'st.sound_category_name')
				->leftjoin('tbl_sound_category as st', 'tbl_sound.sound_category_id', 'st.sound_category_id')
				->offset($start)
				->limit($limit)
				->orderBy($order, $dir)
				->get();

			$totalData = $totalFiltered = Sound::where('is_deleted', 0)->whereIn('added_by', ['admin', 'shazam'])->count();
		} else {
			$search = $request->input('search.value');
			$SoundData = Sound::where('tbl_sound.is_deleted', 0)
				->whereIn('added_by', ['admin', 'shazam']) // Include both admin and Shazam tracks
				->select('tbl_sound.*', 'st.sound_category_name')
				->leftjoin('tbl_sound_category as st', 'tbl_sound.sound_category_id', 'st.sound_category_id')
				->where(function ($query) use ($search) {
					$query->where('tbl_sound.sound_title', 'LIKE', "%{$search}%")
						->orWhere('tbl_sound.sound', 'LIKE', "%{$search}%")
						->orWhere('tbl_sound.duration', 'LIKE', "%{$search}%")
						->orWhere('tbl_sound.singer', 'LIKE', "%{$search}%")
						->orWhere('st.sound_category_name', 'LIKE', "%{$search}%");
				})
				->offset($start)
				->limit($limit)
				->orderBy($order, $dir)
				->get();

			$totalData = $totalFiltered = Sound::where('tbl_sound.is_deleted', 0)
				->whereIn('added_by', ['admin', 'shazam']) // Include both admin and Shazam tracks
				->select('tbl_sound.*', 'st.sound_category_name')
				->leftjoin('tbl_sound_category as st', 'tbl_sound.sound_category_id', 'st.sound_category_id')
				->where(function ($query) use ($search) {
					$query->where('tbl_sound.sound_title', 'LIKE', "%{$search}%")
						->orWhere('tbl_sound.duration', 'LIKE', "%{$search}%")
						->orWhere('tbl_sound.singer', 'LIKE', "%{$search}%")
						->orWhere('st.sound_category_name', 'LIKE', "%{$search}%");
				})
				->count();
		}

		$data = array();
		if (!empty($SoundData)) {
			foreach ($SoundData as $rows) {

				if (!empty($rows->sound_image)) {
					$sound_image = '<img height="60" width="60" src="' . url(env('DEFAULT_IMAGE_URL') . $rows->sound_image) . '">';
				} else {
					$sound_image = '<img height="60px;" width="60px;" src="' . asset('assets/dist/img/default.png') . '">';
				}

				if (!empty($rows->sound)) {
					$sound = '<audio controls>
					<source src="' . url(env('DEFAULT_IMAGE_URL') . $rows->sound) . '" type="audio/mpeg">
					</audio>';
				} else {
					$sound = '';
				}
				if (Session::get('admin_id') == 2) {
					$disabled = "disabled";
				} else {
					$disabled = "";
				}
				$data[] = array(
					$sound_image,
					$sound,
					$rows->sound_category_name,
					$rows->sound_title,
					$rows->duration,
					$rows->singer,
					'<a class="UpdateSound" data-toggle="modal" data-target="#soundModal" data-id="' . $rows->sound_id . '" ' . $disabled . '><i class="i-cl-3 fas fa-edit col-blue font-20 pointer p-l-5 p-r-5"></i></a>
					<a class="delete DeleteSound" data-id="' . $rows->sound_id . '" ' . $disabled . '><i class="fas fa-trash text-danger font-20 pointer p-l-5 p-r-5"></i></a>'
				);
			}
		}
		$json_data = array(
			"draw"            => intval($request->input('draw')),
			"recordsTotal"    => intval($totalData),
			"recordsFiltered" => intval($totalFiltered),
			"data"            => $data
		);

		echo json_encode($json_data);
		exit();
	}

	public function showSoundCategoryList(Request $request)
	{

		$columns = array(
			0 => 'sound_category_id',
			1 => 'sound_category_name',
		);

		$limit = $request->input('length');
		$start = $request->input('start');
		$order = $columns[$request->input('order.0.column')];
		$dir = $request->input('order.0.dir');

		if (empty($request->input('search.value'))) {

			$SoundData = SoundCategory::where('is_deleted', 0)
				->offset($start)
				->limit($limit)
				->orderBy($order, $dir)
				->get();

			$totalData = $totalFiltered = SoundCategory::where('is_deleted', 0)->count();
		} else {
			$search = $request->input('search.value');
			$SoundData = SoundCategory::where('is_deleted', 0)
				->where(function ($query) use ($search) {
					$query->where('sound_category_id', 'LIKE', "%{$search}%")
						->orWhere('sound_category_name', 'LIKE', "%{$search}%");
				})
				->offset($start)
				->limit($limit)
				->orderBy($order, $dir)
				->get();

			$totalData = $totalFiltered = SoundCategory::where('is_deleted', 0)
				->where(function ($query) use ($search) {
					$query->where('sound_category_id', 'LIKE', "%{$search}%")
						->orWhere('sound_category_name', 'LIKE', "%{$search}%");
				})
				->count();
		}

		$data = array();
		if (!empty($SoundData)) {
			foreach ($SoundData as $rows) {

				if (!empty($rows->sound_category_profile)) {
					$sound_category_profile = '<img height="60" width="60" src="' . url(env('DEFAULT_IMAGE_URL') . $rows->sound_category_profile) . '">';
				} else {
					$sound_category_profile = '<img height="60px;" width="60px;" src="' . asset('assets/dist/img/default.png') . '">';
				}
				if (Session::get('admin_id') == 2) {
					$disabled = "disabled";
				} else {
					$disabled = "";
				}
				$data[] = array(
					$sound_category_profile,
					$rows->sound_category_name,
					'<a class="UpdateSoundCategory" data-toggle="modal" data-target="#soundCategoryModal" data-id="' . $rows->sound_category_id . '" data-name="' . $rows->sound_category_name . '" data-src="' . url(env('DEFAULT_IMAGE_URL') . $rows->sound_category_profile) . '" ' . $disabled . '><i class="i-cl-3 fas fa-edit col-blue font-20 pointer p-l-5 p-r-5"></i></a>
					<a class="delete DeleteSoundCategory" data-id="' . $rows->sound_category_id . '" ' . $disabled . '><i class="fas fa-trash text-danger font-20 pointer p-l-5 p-r-5"></i></a>'
				);
			}
		}
		$json_data = array(
			"draw"            => intval($request->input('draw')),
			"recordsTotal"    => intval($totalData),
			"recordsFiltered" => intval($totalFiltered),
			"data"            => $data
		);

		echo json_encode($json_data);
		exit();
	}

	/**
	 * View bulk import sounds page
	 *
	 * @return \Illuminate\View\View
	 */
	public function viewBulkImport()
	{
		$sound_category_data = SoundCategory::where('is_deleted', 0)->orderBy('sound_category_id', 'DESC')->get();
		return view('admin.sound.bulk_import')->with('sound_category_data', $sound_category_data);
	}

	/**
	 * Download CSV template for bulk import
	 *
	 * @return \Symfony\Component\HttpFoundation\StreamedResponse
	 */
	public function downloadTemplate()
	{
		$headers = [
			'Content-Type' => 'text/csv',
			'Content-Disposition' => 'attachment; filename="sounds_import_template.csv"',
			'Pragma' => 'no-cache',
			'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
			'Expires' => '0'
		];

		$callback = function() {
			$file = fopen('php://output', 'w');
			
			// Add CSV header
			fputcsv($file, [
				'sound_category_id',
				'sound_title',
				'singer', 
				'duration',
				'sound_filename',
				'image_filename'
			]);
			
			// Add example row
			fputcsv($file, [
				'1', // Replace with an actual category ID
				'Example Sound Title',
				'Artist Name',
				'00:30', // Duration in mm:ss format
				'example_sound.mp3', // Must match filename in ZIP
				'example_image.jpg' // Optional, must match filename in ZIP if provided
			]);
			
			fclose($file);
		};

		return response()->stream($callback, 200, $headers);
	}

	/**
	 * Process bulk import of sounds
	 *
	 * @param Request $request
	 * @return \Illuminate\Http\JsonResponse
	 */
	public function processBulkImport(Request $request)
	{
		$logFile = storage_path('logs/bulk_import.log');
		$debugLog = function($message) use ($logFile) {
			$timestamp = date('Y-m-d H:i:s');
			$logMessage = "[{$timestamp}] {$message}" . PHP_EOL;
			file_put_contents($logFile, $logMessage, FILE_APPEND);
			\Log::info($message);
		};

		try {
			$debugLog("Starting bulk import process");
			
			// Validate request
			if (!$request->hasFile('csv_file') || !$request->hasFile('zip_file')) {
				$debugLog("Missing required files");
				return response()->json([
					'success' => false,
					'message' => 'Both CSV and ZIP files are required'
				], 400);
			}

			$debugLog("Files present in request");
			
			$validator = Validator::make($request->all(), [
				'csv_file' => 'required|file|mimes:csv,txt|max:102400',
				'zip_file' => 'required|file|mimes:zip|max:1048576',
			]);

			if ($validator->fails()) {
				$debugLog("Validation failed: " . json_encode($validator->errors()));
				return response()->json([
					'success' => false,
					'message' => 'Validation failed',
					'errors' => $validator->errors()
				], 422);
			}

			$debugLog("Files validated successfully");

			// Create a unique temp directory for extraction
			$timestamp = now()->format('YmdHis');
			$tempDir = storage_path('app/temp/bulk_import_' . $timestamp);
			
			if (!File::exists($tempDir)) {
				$debugLog("Creating temp directory: " . $tempDir);
				File::makeDirectory($tempDir, 0755, true);
			}

			try {
				// Extract ZIP file
				$zipPath = $request->file('zip_file')->getRealPath();
				$debugLog("ZIP file path: " . $zipPath);
				
				$zip = new \ZipArchive();
				$openResult = $zip->open($zipPath);
				
				if ($openResult !== true) {
					$debugLog("Failed to open ZIP file. Error code: " . $openResult);
					throw new \Exception('Could not open the ZIP file');
				}
				
				$debugLog("ZIP file opened successfully");
				$extractResult = $zip->extractTo($tempDir);
				
				if (!$extractResult) {
					$debugLog("Failed to extract ZIP file");
					throw new \Exception('Failed to extract ZIP file');
				}
				
				$zip->close();
				$debugLog("ZIP file extracted successfully");
				
				// Process CSV file
				$csvPath = $request->file('csv_file')->getRealPath();
				$debugLog("CSV file path: " . $csvPath);
				
				if (!($csvFile = fopen($csvPath, 'r'))) {
					$debugLog("Failed to open CSV file");
					throw new \Exception('Could not open CSV file');
				}
				
				// Skip header row
				$header = fgetcsv($csvFile);
				$debugLog("CSV header: " . implode(', ', $header));
				
				// Validate header
				$expectedHeader = ['sound_category_id', 'sound_title', 'singer', 'duration', 'sound_filename', 'image_filename'];
				
				if (count(array_diff($expectedHeader, $header)) > 0) {
					$debugLog("Invalid CSV header. Expected: " . implode(', ', $expectedHeader) . ', Got: ' . implode(', ', $header));
					File::deleteDirectory($tempDir);
					return response()->json([
						'success' => false,
						'message' => 'CSV header does not match expected format. Please use the template provided.'
					], 400);
				}
				
				// Initialize counters and error log
				$totalRows = 0;
				$successCount = 0;
				$errorCount = 0;
				$errors = [];
				
				// Process each row
				while (($row = fgetcsv($csvFile)) !== false) {
					$totalRows++;
					$rowNum = $totalRows + 1; // +1 for header row
					$debugLog("Processing row {$rowNum}: " . implode(', ', $row));
					
					try {
						// Map CSV columns to variables
						$categoryId = trim($row[0] ?? '');
						$title = trim($row[1] ?? '');
						$singer = trim($row[2] ?? '');
						$duration = trim($row[3] ?? '');
						$soundFilename = trim($row[4] ?? '');
						$imageFilename = trim($row[5] ?? '');
						
						// Basic validation
						if (empty($categoryId) || empty($title) || empty($soundFilename)) {
							throw new \Exception("Missing required fields (category_id, title, or sound_filename)");
						}

						// Validate duration format (mm:ss)
						if (!preg_match('/^([0-5]?[0-9]):([0-5][0-9])$/', $duration)) {
							throw new \Exception("Invalid duration format. Please use mm:ss format (e.g., 03:45)");
						}
						
						// Check if sound category exists
						$category = SoundCategory::where('sound_category_id', $categoryId)
							->where('is_deleted', 0)
							->first();
						
						if (!$category) {
							throw new \Exception("Sound category ID {$categoryId} does not exist");
						}
						
						// Check if sound file exists in ZIP
						$soundFilePath = $tempDir . DIRECTORY_SEPARATOR . $soundFilename;
						$debugLog("Checking sound file: {$soundFilePath}");
						
						if (!File::exists($soundFilePath)) {
							throw new \Exception("Sound file '{$soundFilename}' not found in ZIP archive");
						}
						
						// Check image file if provided
						$imageFilePath = null;
						if (!empty($imageFilename)) {
							$imageFilePath = $tempDir . DIRECTORY_SEPARATOR . $imageFilename;
							$debugLog("Checking image file: {$imageFilePath}");
							
							if (!File::exists($imageFilePath)) {
								throw new \Exception("Image file '{$imageFilename}' not found in ZIP archive");
							}
						}
						
						// Create temporary UploadedFile objects for S3 upload
						$debugLog("Creating UploadedFile for sound");
						$soundFileSize = filesize($soundFilePath);
						$soundMimeType = File::mimeType($soundFilePath);
						$soundUploadedFile = new \Illuminate\Http\UploadedFile(
							$soundFilePath,
							$soundFilename,
							$soundMimeType,
							$soundFileSize,
							true
						);
						
						// Upload sound file to S3
						$debugLog("Uploading sound file to S3");
						$s3SoundPath = GlobalFunction::uploadFilToS3($soundUploadedFile);
						$debugLog("Sound file uploaded to: {$s3SoundPath}");
						
						// Upload image file to S3 if provided
						$s3ImagePath = null;
						if (!empty($imageFilePath)) {
							$debugLog("Creating UploadedFile for image");
							$imageFileSize = filesize($imageFilePath);
							$imageMimeType = File::mimeType($imageFilePath);
							$imageUploadedFile = new \Illuminate\Http\UploadedFile(
								$imageFilePath,
								$imageFilename,
								$imageMimeType,
								$imageFileSize,
								true
							);
							
							$debugLog("Uploading image file to S3");
							$s3ImagePath = GlobalFunction::uploadFilToS3($imageUploadedFile);
							$debugLog("Image file uploaded to: {$s3ImagePath}");
						}
						
						// Create new Sound record
						$debugLog("Creating new Sound record");
						$sound = new Sound();
						$sound->sound_category_id = $categoryId;
						$sound->sound_title = $title;
						$sound->singer = $singer;
						$sound->duration = $duration;
						$sound->sound = $s3SoundPath;
						
						if ($s3ImagePath) {
							$sound->sound_image = $s3ImagePath;
						}
						
						$sound->is_deleted = 0;
						$sound->added_by = 'admin';
						
						$debugLog("Saving Sound record");
						$sound->save();
						$debugLog("Sound record saved successfully with ID: {$sound->sound_id}");
						
						$successCount++;
						
					} catch (\Exception $e) {
						$debugLog("Error processing row {$rowNum}: " . $e->getMessage());
						$errorCount++;
						$errors[] = "Row {$rowNum}: " . $e->getMessage();
						continue;
					}
				}
				
				fclose($csvFile);
				
				// Clean up temp directory
				$debugLog("Cleaning up temp directory");
				File::deleteDirectory($tempDir);
				
				$debugLog("Bulk import completed. Success: {$successCount}, Errors: {$errorCount}");
				
				// Return results
				return response()->json([
					'success' => true,
					'message' => "Bulk import completed. Successfully imported {$successCount} sounds.",
					'details' => [
						'total' => $totalRows,
						'success' => $successCount,
						'error' => $errorCount,
						'errors' => $errors
					]
				]);
				
			} catch (\Exception $e) {
				$debugLog("Error during file processing: " . $e->getMessage());
				// Clean up temp directory in case of exception
				if (File::exists($tempDir)) {
					File::deleteDirectory($tempDir);
				}
				
				throw $e;
			}
			
		} catch (\Exception $e) {
			$debugLog("Bulk import failed: " . $e->getMessage());
			return response()->json([
				'success' => false,
				'message' => 'An error occurred during import: ' . $e->getMessage()
			], 500);
		}
	}
}
