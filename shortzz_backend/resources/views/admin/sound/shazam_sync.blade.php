@extends('admin_layouts/main')

@section('pageSpecificCss')
    <link href="{{ asset('assets/bundles/izitoast/css/iziToast.min.css') }}" rel="stylesheet">
@stop

@section('content')
<section class="section">
    <div class="section-body">
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h4>Shazam Music Sync</h4>
                    </div>
                    <div class="card-body">
                        <div class="row mb-4">
                            <div class="col-md-6">
                                <div class="card card-statistic-1">
                                    <div class="card-icon bg-primary">
                                        <i class="fas fa-clock"></i>
                                    </div>
                                    <div class="card-wrap">
                                        <div class="card-header">
                                            <h4>Last Synchronization</h4>
                                        </div>
                                        <div class="card-body" id="lastSyncTime">
                                            {{ $last_sync }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card card-statistic-1">
                                    <div class="card-icon bg-success">
                                        <i class="fas fa-music"></i>
                                    </div>
                                    <div class="card-wrap">
                                        <div class="card-header">
                                            <h4>Shazam Tracks</h4>
                                        </div>
                                        <div class="card-body">
                                            <span id="shazamTracksCount">{{ $shazam_tracks }}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row mt-4">
                            <div class="col-md-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h4>API Settings</h4>
                                    </div>
                                    <div class="card-body">
                                        <form id="shazamSettingsForm" action="{{ url('/admin/settings/list') }}" method="post" class="form-group form-border">
                                            @csrf
                                            <input type="hidden" name="_method" value="POST">
                                            <div class="form-group">
                                                <label for="shazam_api_key">Shazam API Key</label>
                                                <input type="password" class="form-control" id="shazam_api_key" name="shazam_api_key" 
                                                    value="{{ $settings->shazam_api_key ?? '' }}" placeholder="Enter your Shazam API key">
                                                <small class="text-muted">Get your API key from <a href="https://rapidapi.com/apidojo/api/shazam" target="_blank">RapidAPI Shazam</a></small>
                                            </div>
                                            <div class="form-group">
                                                <label for="shazam_api_host">API Host</label>
                                                <input type="text" class="form-control" id="shazam_api_host" name="shazam_api_host" 
                                                    value="{{ $settings->shazam_api_host ?? 'shazam.p.rapidapi.com' }}" placeholder="shazam.p.rapidapi.com">
                                            </div>
                                            <div class="form-group text-right">
                                                <button type="button" id="testApiBtn" class="btn btn-warning mr-2">Test API Connection</button>
                                            </div>
                                            <div id="apiTestResults" class="alert mt-3" style="display: none;"></div>
                                            <div class="form-group">
                                                <label for="shazam_tracks_limit">Number of tracks to sync</label>
                                                <input type="number" class="form-control" id="shazam_tracks_limit" name="shazam_tracks_limit" 
                                                    value="{{ $settings->shazam_tracks_limit ?? 50 }}" min="10" max="200">
                                            </div>
                                            <div class="form-group text-right">
                                                <button type="submit" class="btn btn-primary">Save Settings</button>
                                                <span class="ml-2"><small>(You'll be redirected to the main settings page)</small></span>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row mt-4">
                            <div class="col-md-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h4>Manual Synchronization</h4>
                                    </div>
                                    <div class="card-body">
                                        <p>
                                            Tracks are automatically synchronized every month. 
                                            You can also manually trigger a synchronization by clicking the button below.
                                        </p>
                                        <button id="syncNowBtn" class="btn btn-success btn-lg">Sync Now</button>
                                        <div id="syncStatus" class="mt-3" style="display: none;">
                                            <div class="progress mb-3">
                                                <div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" id="syncProgressBar" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">Syncing...</div>
                                            </div>
                                        </div>
                                        <div id="syncResults" class="alert mt-3" style="display: none;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection

@section('pageSpecificJs')
    <script src="{{ asset('assets/bundles/izitoast/js/iziToast.min.js') }}"></script>
    <script>
$(document).ready(function() {
    // Original AJAX form submission replaced with direct form submission
    // This avoids route resolution issues between development and production environments
    
    // Test API Connection button
    $('#testApiBtn').on('click', function() {
        const apiKey = $('#shazam_api_key').val();
        const apiHost = $('#shazam_api_host').val();
        
        if (!apiKey || !apiHost) {
            $('#apiTestResults').show().removeClass('alert-success').addClass('alert-danger')
                .html('<strong>Error!</strong> Please enter API key and host before testing.');
            return;
        }
        
        $(this).prop('disabled', true).html('Testing...');
        $('#apiTestResults').hide();
        
        $.ajax({
            url: "{{ route('testShazamApiConnection') }}",
            type: "POST",
            dataType: 'json',
            data: {
                _token: "{{ csrf_token() }}"
            },
            headers: {
                'Accept': 'application/json'
            },
            success: function(response) {
                $('#testApiBtn').prop('disabled', false).html('Test API Connection');
                $('#apiTestResults').show();
                
                if (response && response.success === 1) {
                    $('#apiTestResults').removeClass('alert-danger').addClass('alert-success');
                    $('#apiTestResults').html(
                        `<strong>Success!</strong> ${response.message}<br>
                        <ul>
                            <li>Status Code: ${response.data.status_code}</li>
                            <li>Response Length: ${response.data.response_length} bytes</li>
                            <li>Sample: <code>${response.data.sample}</code></li>
                        </ul>`
                    );
                    
                    iziToast.success({
                        title: 'Success',
                        message: 'API connection successful',
                        position: 'topRight'
                    });
                } else {
                    $('#apiTestResults').removeClass('alert-success').addClass('alert-danger');
                    $('#apiTestResults').html(`<strong>Error!</strong> ${response && response.message ? response.message : 'Unknown error connecting to API'}`);
                    
                    iziToast.error({
                        title: 'Error',
                        message: response && response.message ? response.message : 'Unknown error connecting to API',
                        position: 'topRight'
                    });
                }
            },
            error: function(xhr, status, error) {
                $('#testApiBtn').prop('disabled', false).html('Test API Connection');
                $('#apiTestResults').show().removeClass('alert-success').addClass('alert-danger');
                
                // Check if response is HTML instead of JSON (server error page)
                let errorMsg = 'Failed to communicate with server';
                if (xhr.responseText && xhr.responseText.includes('<!DOCTYPE html>')) {
                    console.error('Server returned HTML instead of JSON:', xhr.responseText.substring(0, 500));
                    errorMsg = 'Server returned HTML instead of JSON. Check server logs for details.';
                } else if (xhr.responseJSON && xhr.responseJSON.message) {
                    errorMsg = xhr.responseJSON.message;
                }
                
                $('#apiTestResults').html(`<strong>Error!</strong> ${errorMsg}`);
                
                iziToast.error({
                    title: 'Test Failed',
                    message: errorMsg,
                    position: 'topRight'
                });
            },
            timeout: 30000 // 30-second timeout
        });
    });
    
    // Manual sync button
    $('#syncNowBtn').on('click', function() {
        $('#syncStatus').show();
        $('#syncResults').hide();
        $(this).prop('disabled', true);
        
        iziToast.info({
            title: 'Sync Started',
            message: 'Synchronizing tracks from Shazam...',
            position: 'topRight',
            timeout: 2000
        });
        
        $.ajax({
            url: "{{ route('syncShazamMusic') }}",
            type: "POST",
            dataType: 'json',
            data: {
                _token: "{{ csrf_token() }}"
            },
            headers: {
                'Accept': 'application/json'
            },
            success: function(response) {
                $('#syncStatus').hide();
                $('#syncNowBtn').prop('disabled', false);
                $('#syncResults').show();
                
                if (response && response.success === 1) {
                    $('#syncResults').removeClass('alert-danger').addClass('alert-success');
                    $('#syncResults').html(
                        `<strong>Success!</strong> ${response.message}<br>
                        <ul>
                            <li>Added: ${response.data.added} tracks</li>
                            <li>Updated: ${response.data.updated} tracks</li>
                            <li>Skipped: ${response.data.skipped} tracks</li>
                        </ul>
                        Last sync: ${response.data.last_sync}`
                    );
                    $('#lastSyncTime').text(response.data.last_sync);
                    $('#shazamTracksCount').text(parseInt($('#shazamTracksCount').text()) + response.data.added);
                    
                    iziToast.success({
                        title: 'Success',
                        message: response.message,
                        position: 'topRight'
                    });
                } else {
                    $('#syncResults').removeClass('alert-success').addClass('alert-danger');
                    $('#syncResults').html(`<strong>Error!</strong> ${response && response.message ? response.message : 'Unknown error during sync'}`);
                    
                    iziToast.error({
                        title: 'Error',
                        message: response && response.message ? response.message : 'Unknown error during sync',
                        position: 'topRight'
                    });
                }
            },
            error: function(xhr, status, error) {
                $('#syncStatus').hide();
                $('#syncNowBtn').prop('disabled', false);
                $('#syncResults').show().removeClass('alert-success').addClass('alert-danger');
                
                // Check if response is HTML instead of JSON (server error page)
                let errorMsg = 'Failed to communicate with server';
                if (xhr.responseText && xhr.responseText.includes('<!DOCTYPE html>')) {
                    console.error('Server returned HTML instead of JSON:', xhr.responseText.substring(0, 500));
                    errorMsg = 'Server returned HTML instead of JSON. Check server logs for details.';
                } else if (xhr.responseJSON && xhr.responseJSON.message) {
                    errorMsg = xhr.responseJSON.message;
                }
                
                $('#syncResults').html(`<strong>Error!</strong> ${errorMsg}`);
                
                iziToast.error({
                    title: 'Sync Failed',
                    message: errorMsg,
                    position: 'topRight'
                });
            },
            // Add a timeout to prevent hanging
            timeout: 60000 // 1-minute timeout
        });
    });
});
</script>
@endsection
