@extends('admin.layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">App Versions</h3>
                    <div class="card-tools">
                        <a href="{{ route('admin.app-versions.create') }}" class="btn btn-primary">
                            <i class="fas fa-plus"></i> Add New Version
                        </a>
                    </div>
                </div>
                <div class="card-body">
                    @if(session('success'))
                        <div class="alert alert-success">
                            {{ session('success') }}
                        </div>
                    @endif

                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Minimum Version</th>
                                <th>Latest Version</th>
                                <th>Force Update</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($versions as $version)
                                <tr>
                                    <td>{{ $version->id }}</td>
                                    <td>{{ $version->minimum_version }}</td>
                                    <td>{{ $version->latest_version }}</td>
                                    <td>
                                        <span class="badge badge-{{ $version->force_update ? 'danger' : 'success' }}">
                                            {{ $version->force_update ? 'Yes' : 'No' }}
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge badge-{{ $version->is_active ? 'success' : 'secondary' }}">
                                            {{ $version->is_active ? 'Active' : 'Inactive' }}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="btn-group">
                                            <a href="{{ route('admin.app-versions.edit', $version) }}" 
                                               class="btn btn-sm btn-info">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            @if(!$version->is_active)
                                                <form action="{{ route('admin.app-versions.set-active', $version) }}" 
                                                      method="POST" style="display: inline;">
                                                    @csrf
                                                    <button type="submit" class="btn btn-sm btn-success">
                                                        <i class="fas fa-check"></i>
                                                    </button>
                                                </form>
                                            @endif
                                            <form action="{{ route('admin.app-versions.destroy', $version) }}" 
                                                  method="POST" style="display: inline;"
                                                  onsubmit="return confirm('Are you sure you want to delete this version?');">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-sm btn-danger">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection 