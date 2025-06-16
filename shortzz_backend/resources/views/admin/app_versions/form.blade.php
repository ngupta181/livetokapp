@extends('admin.layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">{{ isset($appVersion) ? 'Edit App Version' : 'Create New App Version' }}</h3>
                </div>
                <div class="card-body">
                    @if ($errors->any())
                        <div class="alert alert-danger">
                            <ul>
                                @foreach ($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif

                    <form action="{{ isset($appVersion) ? route('admin.app-versions.update', $appVersion) : route('admin.app-versions.store') }}" 
                          method="POST">
                        @csrf
                        @if(isset($appVersion))
                            @method('PUT')
                        @endif

                        <div class="form-group">
                            <label for="minimum_version">Minimum Version</label>
                            <input type="text" name="minimum_version" id="minimum_version" 
                                   class="form-control @error('minimum_version') is-invalid @enderror"
                                   value="{{ old('minimum_version', $appVersion->minimum_version ?? '') }}" 
                                   placeholder="e.g. 1.0.0" required>
                        </div>

                        <div class="form-group">
                            <label for="latest_version">Latest Version</label>
                            <input type="text" name="latest_version" id="latest_version" 
                                   class="form-control @error('latest_version') is-invalid @enderror"
                                   value="{{ old('latest_version', $appVersion->latest_version ?? '') }}" 
                                   placeholder="e.g. 1.0.0" required>
                        </div>

                        <div class="form-group">
                            <label for="update_message">Update Message</label>
                            <textarea name="update_message" id="update_message" 
                                      class="form-control @error('update_message') is-invalid @enderror"
                                      rows="3" placeholder="Enter update message">{{ old('update_message', $appVersion->update_message ?? '') }}</textarea>
                        </div>

                        <div class="form-group">
                            <label for="play_store_url">Play Store URL</label>
                            <input type="url" name="play_store_url" id="play_store_url" 
                                   class="form-control @error('play_store_url') is-invalid @enderror"
                                   value="{{ old('play_store_url', $appVersion->play_store_url ?? '') }}" 
                                   placeholder="https://play.google.com/store/apps/..." required>
                        </div>

                        <div class="form-group">
                            <label for="app_store_url">App Store URL</label>
                            <input type="url" name="app_store_url" id="app_store_url" 
                                   class="form-control @error('app_store_url') is-invalid @enderror"
                                   value="{{ old('app_store_url', $appVersion->app_store_url ?? '') }}" 
                                   placeholder="https://apps.apple.com/..." required>
                        </div>

                        <div class="form-group">
                            <div class="custom-control custom-checkbox">
                                <input type="checkbox" class="custom-control-input" 
                                       id="force_update" name="force_update" value="1"
                                       {{ old('force_update', $appVersion->force_update ?? false) ? 'checked' : '' }}>
                                <label class="custom-control-label" for="force_update">Force Update</label>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="custom-control custom-checkbox">
                                <input type="checkbox" class="custom-control-input" 
                                       id="is_active" name="is_active" value="1"
                                       {{ old('is_active', $appVersion->is_active ?? false) ? 'checked' : '' }}>
                                <label class="custom-control-label" for="is_active">Set as Active Version</label>
                            </div>
                        </div>

                        <div class="form-group">
                            <button type="submit" class="btn btn-primary">
                                {{ isset($appVersion) ? 'Update' : 'Create' }}
                            </button>
                            <a href="{{ route('admin.app-versions.index') }}" class="btn btn-secondary">Cancel</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection 