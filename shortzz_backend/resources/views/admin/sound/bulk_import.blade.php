@extends('admin_layouts/main')
@section('title', 'Bulk Import Sounds')
@section('css')
<style>
    .upload-instructions {
        background-color: #f8f9fa;
        border-left: 4px solid #007bff;
        padding: 15px;
        margin-bottom: 20px;
    }
    .step {
        margin-bottom: 10px;
    }
    .step-number {
        display: inline-block;
        width: 25px;
        height: 25px;
        line-height: 25px;
        text-align: center;
        background: #007bff;
        color: white;
        border-radius: 50%;
        margin-right: 10px;
    }
    .card-header {
        background-color: #f8f9fa;
    }
    .result-box {
        display: none;
        margin-top: 20px;
    }
</style>
@endsection

@section('content')
<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1>Bulk Import Sounds</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="{{route('dashboard')}}">Home</a></li>
                        <li class="breadcrumb-item"><a href="{{route('sound/list')}}">Sound List</a></li>
                        <li class="breadcrumb-item active">Bulk Import</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Bulk Import Instructions</h3>
                        </div>
                        <div class="card-body">
                            <div class="upload-instructions">
                                <h5>How to use the bulk import tool:</h5>
                                <div class="step">
                                    <span class="step-number">1</span>
                                    <span>Download the CSV template by clicking <a href="{{ route('downloadSoundTemplate') }}" class="text-primary">here</a>.</span>
                                </div>
                                <div class="step">
                                    <span class="step-number">2</span>
                                    <span>Fill in the template with your sound details.</span>
                                </div>
                                <div class="step">
                                    <span class="step-number">3</span>
                                    <span>Create a ZIP file containing all your sound files and image files referenced in the CSV.</span>
                                </div>
                                <div class="step">
                                    <span class="step-number">4</span>
                                    <span>Upload both the CSV file and ZIP file using the form below.</span>
                                </div>
                            </div>

                            <div class="card mt-4">
                                <div class="card-header">
                                    <h4 class="card-title">Available Sound Categories</h4>
                                </div>
                                <div class="card-body">
                                    <div class="table-responsive">
                                        <table class="table table-bordered table-hover">
                                            <thead>
                                                <tr>
                                                    <th>Category ID</th>
                                                    <th>Category Name</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                @foreach($sound_category_data as $category)
                                                <tr>
                                                    <td>{{ $category->sound_category_id }}</td>
                                                    <td>{{ $category->sound_category_name }}</td>
                                                </tr>
                                                @endforeach
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <form id="bulkImportForm" class="mt-4">
                                @csrf
                                <div class="form-group">
                                    <label for="csv_file">CSV File</label>
                                    <div class="input-group">
                                        <div class="custom-file">
                                            <input type="file" class="custom-file-input" id="csv_file" name="csv_file" accept=".csv,.txt" required>
                                            <label class="custom-file-label" for="csv_file">Choose CSV file</label>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">Upload a CSV file with sound details (max 2MB)</small>
                                </div>
                                <div class="form-group">
                                    <label for="zip_file">ZIP File</label>
                                    <div class="input-group">
                                        <div class="custom-file">
                                            <input type="file" class="custom-file-input" id="zip_file" name="zip_file" accept=".zip" required>
                                            <label class="custom-file-label" for="zip_file">Choose ZIP file</label>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">Upload a ZIP file containing all your sound files and images (max 100MB)</small>
                                </div>
                                <div class="form-group">
                                    <button type="submit" class="btn btn-primary" id="import-btn">
                                        <i class="fas fa-upload"></i> Import Sounds
                                    </button>
                                    <a href="{{ route('sound/list') }}" class="btn btn-default">
                                        <i class="fas fa-arrow-left"></i> Back to Sound List
                                    </a>
                                </div>
                            </form>

                            <div class="result-box alert" id="result-box">
                                <h5 id="result-title"></h5>
                                <div id="result-message"></div>
                                <div id="result-details" class="mt-3"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>
@endsection

@section('script')
<script src="{{ asset('assets/plugins/bs-custom-file-input/bs-custom-file-input.min.js') }}"></script>
<script>
$(document).ready(function() {
    bsCustomFileInput.init();

    function showError(message, details = '') {
        $('#result-box').removeClass('alert-success').addClass('alert-danger');
        $('#result-title').text('Import Failed');
        $('#result-message').text(message);
        $('#result-details').html(details);
        $('#result-box').show();
        
        $('html, body').animate({
            scrollTop: $('#result-box').offset().top - 100
        }, 200);
    }

    $('#bulkImportForm').on('submit', function(e) {
        e.preventDefault();
        
        // Validate files
        var csvFile = $('#csv_file')[0].files[0];
        var zipFile = $('#zip_file')[0].files[0];
        
        if (!csvFile || !zipFile) {
            showError('Please select both CSV and ZIP files.');
            return;
        }
        
        // Validate file types
        if (!csvFile.name.toLowerCase().endsWith('.csv')) {
            showError('Please select a valid CSV file.');
            return;
        }
        
        if (!zipFile.name.toLowerCase().endsWith('.zip')) {
            showError('Please select a valid ZIP file.');
            return;
        }
        
        // Validate file sizes
        if (csvFile.size > 2 * 1024 * 1024) { // 2MB
            showError('CSV file size must be less than 2MB.');
            return;
        }
        
        if (zipFile.size > 100 * 1024 * 1024) { // 100MB
            showError('ZIP file size must be less than 100MB.');
            return;
        }
        
        // Show loading state
        $('#import-btn').html('<i class="fas fa-spinner fa-spin"></i> Processing...');
        $('#import-btn').attr('disabled', true);
        $('#result-box').hide();
        
        var formData = new FormData(this);
        
        // Add CSRF token
        formData.append('_token', '{{ csrf_token() }}');
        
        $.ajax({
            url: '{{ route("processBulkImport") }}',
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            xhr: function() {
                var xhr = new window.XMLHttpRequest();
                xhr.upload.addEventListener("progress", function(evt) {
                    if (evt.lengthComputable) {
                        var percentComplete = evt.loaded / evt.total;
                        $('#import-btn').html('<i class="fas fa-spinner fa-spin"></i> Uploading... ' + Math.round(percentComplete * 100) + '%');
                    }
                }, false);
                return xhr;
            },
            success: function(response) {
                console.log('Success response:', response);
                
                // Reset button state
                $('#import-btn').html('<i class="fas fa-upload"></i> Import Sounds');
                $('#import-btn').attr('disabled', false);
                
                // Show result
                $('#result-box').removeClass('alert-danger alert-success');
                $('#result-box').addClass(response.success ? 'alert-success' : 'alert-danger');
                $('#result-title').text(response.success ? 'Import Successful' : 'Import Failed');
                $('#result-message').text(response.message);
                
                // Show details if available
                if (response.details) {
                    var details = '';
                    details += '<p><strong>Total rows:</strong> ' + response.details.total + '</p>';
                    details += '<p><strong>Successfully imported:</strong> ' + response.details.success + '</p>';
                    details += '<p><strong>Errors:</strong> ' + response.details.error + '</p>';
                    
                    if (response.details.errors && response.details.errors.length > 0) {
                        details += '<div class="mt-3"><strong>Error Details:</strong></div>';
                        details += '<ul>';
                        $.each(response.details.errors, function(index, error) {
                            details += '<li>' + error + '</li>';
                        });
                        details += '</ul>';
                    }
                    
                    $('#result-details').html(details);
                }
                
                $('#result-box').show();
                
                // Scroll to result
                $('html, body').animate({
                    scrollTop: $('#result-box').offset().top - 100
                }, 200);
                
                // Reset form if successful
                if (response.success) {
                    $('#bulkImportForm')[0].reset();
                    $('.custom-file-label').text('Choose file');
                }
            },
            error: function(xhr, status, error) {
                console.error('Error:', {xhr: xhr, status: status, error: error});
                
                // Reset button state
                $('#import-btn').html('<i class="fas fa-upload"></i> Import Sounds');
                $('#import-btn').attr('disabled', false);
                
                // Show error
                $('#result-box').removeClass('alert-success').addClass('alert-danger');
                $('#result-title').text('Import Failed');
                
                var errorMessage = 'An error occurred during import.';
                var errorDetails = '';
                
                if (xhr.responseJSON) {
                    console.log('Response JSON:', xhr.responseJSON);
                    
                    if (xhr.responseJSON.message) {
                        errorMessage = xhr.responseJSON.message;
                    }
                    
                    if (xhr.responseJSON.errors) {
                        errorDetails = '<div class="mt-3"><strong>Validation Errors:</strong></div><ul>';
                        $.each(xhr.responseJSON.errors, function(field, errors) {
                            $.each(errors, function(index, error) {
                                errorDetails += '<li>' + error + '</li>';
                            });
                        });
                        errorDetails += '</ul>';
                    }
                }
                
                if (xhr.status === 413) {
                    errorMessage = 'The uploaded file is too large.';
                } else if (xhr.status === 422) {
                    errorMessage = 'Please check your input and try again.';
                } else if (xhr.status === 500) {
                    errorMessage = 'A server error occurred. Please check the logs for details.';
                }
                
                $('#result-message').text(errorMessage);
                $('#result-details').html(errorDetails);
                $('#result-box').show();
                
                // Scroll to error
                $('html, body').animate({
                    scrollTop: $('#result-box').offset().top - 100
                }, 200);
            }
        });
    });
});
</script>
@endsection
