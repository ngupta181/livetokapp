@extends('admin.layouts.app')
@section('title', 'Shazam API Settings')
@section('content')
<div class="content-wrapper">
    <div class="content-header row">
        <div class="content-header-left col-md-9 col-12 mb-2">
            <div class="row breadcrumbs-top">
                <div class="col-12">
                    <h2 class="content-header-title float-left mb-0">Shazam API Settings</h2>
                    <div class="breadcrumb-wrapper col-12">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <a href="{{ route('dashboard') }}">Dashboard</a>
                            </li>
                            <li class="breadcrumb-item active">Shazam API Settings</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="content-body">
        <!-- Stats -->
        <div class="row">
            <div class="col-xl-3 col-md-4 col-sm-6">
                <div class="card text-center">
                    <div class="card-content">
                        <div class="card-body">
                            <div class="avatar bg-rgba-primary p-50 m-0 mb-1">
                                <div class="avatar-content">
                                    <i class="feather icon-music text-primary font-medium-5"></i>
                                </div>
                            </div>
                            <h2 class="text-bold-700">{{ $total_tracks }}</h2>
                            <p class="mb-0 line-ellipsis">Total Shazam Tracks</p>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-4 col-sm-6">
                <div class="card text-center">
                    <div class="card-content">
                        <div class="card-body">
                            <div class="avatar bg-rgba-warning p-50 m-0 mb-1">
                                <div class="avatar-content">
                                    <i class="feather icon-clock text-warning font-medium-5"></i>
                                </div>
                            </div>
                            <h2 class="text-bold-700">{{ $last_sync_date }}</h2>
                            <p class="mb-0 line-ellipsis">Last Sync Date</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Settings Form -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Shazam API Configuration</h4>
                    </div>
                    <div class="card-content">
                        <div class="card-body">
                            <form id="shazamSettingsForm">
                                @csrf
                                <div class="form-group">
                                    <label for="api_key">API Key (from RapidAPI)</label>
                                    <input type="text" class="form-control" id="api_key" name="api_key" value="{{ $api_key }}" placeholder="Enter your Shazam API key from RapidAPI" required>
                                    <small class="form-text text-muted">You can get an API key from <a href="https://rapidapi.com/apidojo/api/shazam" target="_blank">RapidAPI Shazam API</a></small>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-6">
                                        <button type="submit" class="btn btn-primary">Save Settings</button>
                                    </div>
                                    <div class="col-6 text-right">
                                        <button type="button" id="syncNowBtn" class="btn btn-success">Sync Tracks Now</button>
                                        <a href="{{ url('/debug-env') }}" target="_blank" class="btn btn-info ml-2"><i class="feather icon-info"></i> System Info</a>
                                    </div>
                                </div>
                                <div id="apiResponse" class="mt-3" style="display: none;">
                                    <div class="alert alert-info">
                                        <h5>Response Details</h5>
                                        <pre id="responseDetails" style="max-height: 200px; overflow: auto;"></pre>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Instructions -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Instructions</h4>
                    </div>
                    <div class="card-content">
                        <div class="card-body">
                            <ol>
                                <li>Sign up for a <a href="https://rapidapi.com/apidojo/api/shazam" target="_blank">RapidAPI account</a> and subscribe to the Shazam API</li>
                                <li>Copy your API key from RapidAPI and paste it in the field above</li>
                                <li>Click "Save Settings" to store your API key</li>
                                <li>Click "Sync Tracks Now" to manually fetch the latest top tracks from Shazam</li>
                                <li>Tracks will be automatically synced monthly via the scheduled task</li>
                            </ol>
                            <div class="alert alert-info">
                                <strong>Note:</strong> The free tier of RapidAPI has limited requests per month. Be mindful of how often you manually sync.
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@section('script')
<script>
    $(document).ready(function() {
        $.ajaxSetup({
            headers: {
                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
            }
        });
        
        $('#shazamSettingsForm').on('submit', function(e) {
            e.preventDefault();
            
            let apiKey = $('#api_key').val();
            if (!apiKey) {
                toastr.error('Please enter an API key');
                return;
            }
            
            $('#apiResponse').hide();
            
            $.ajax({
                url: "{{ route('shazam/saveSettings') }}",
                type: "POST",
                data: $(this).serialize(),
                dataType: 'json',
                success: function(response) {
                    if (response.success == 1) {
                        toastr.success(response.message);
                    } else {
                        toastr.error(response.message || 'Error saving API key');
                    }
                    
                    // Display debug information
                    if (response.debug) {
                        $('#responseDetails').html(JSON.stringify(response, null, 2));
                        $('#apiResponse').show();
                    }
                },
                error: function(xhr, status, error) {
                    console.error(xhr.responseText);
                    toastr.error('Error saving API key: ' + error);
                    
                    try {
                        // Try to parse response as JSON
                        let response = JSON.parse(xhr.responseText);
                        $('#responseDetails').html(JSON.stringify(response, null, 2));
                        $('#apiResponse').show();
                    } catch (e) {
                        // Show raw response if not JSON
                        $('#responseDetails').text(xhr.responseText || 'No detailed error information available');
                        $('#apiResponse').show();
                    }
                }
            });
        });
        
        $('#syncNowBtn').on('click', function() {
            $(this).prop('disabled', true);
            $(this).html('<i class="spinner-border spinner-border-sm"></i> Syncing...');
            $('#apiResponse').hide();
            
            $.ajax({
                url: "{{ route('shazam/sync') }}",
                type: "POST",
                data: {
                    _token: $('meta[name="csrf-token"]').attr('content')
                },
                success: function(response) {
                    if (response.success == 1) {
                        toastr.success(response.message);
                        // Update the total tracks count
                        $('.text-bold-700').first().text(response.total_tracks);
                        
                        // Display debug information
                        if (response.debug || response.details) {
                            $('#responseDetails').html(JSON.stringify(response, null, 2));
                            $('#apiResponse').show();
                            
                            // Only reload if successful and no major debug info to review
                            if (!response.debug || Object.keys(response.debug).length < 3) {
                                setTimeout(function() {
                                    location.reload();
                                }, 5000); // Give more time to see debug info
                            }
                        } else {
                            // Refresh the page to show the updated last sync date
                            setTimeout(function() {
                                location.reload();
                            }, 2000);
                        }
                    } else {
                        toastr.error(response.message);
                        // Show any error details
                        $('#responseDetails').html(JSON.stringify(response, null, 2));
                        $('#apiResponse').show();
                    }
                    $('#syncNowBtn').prop('disabled', false);
                    $('#syncNowBtn').html('Sync Tracks Now');
                },
                error: function(xhr, status, error) {
                    toastr.error('Error occurred while syncing tracks: ' + error);
                    $('#syncNowBtn').prop('disabled', false);
                    $('#syncNowBtn').html('Sync Tracks Now');
                    
                    try {
                        // Try to parse response as JSON
                        let response = JSON.parse(xhr.responseText);
                        $('#responseDetails').html(JSON.stringify(response, null, 2));
                        $('#apiResponse').show();
                    } catch (e) {
                        // Show raw response if not JSON
                        $('#responseDetails').text(xhr.responseText || 'No detailed error information available');
                        $('#apiResponse').show();
                    }
                }
            });
        });
    });
</script>
@endsection
