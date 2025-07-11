@extends('admin_layouts/main')

@section('content')
<div class="main-content">
    <section class="section">
        <div class="section-header">
            <h1>Blocked IP Management</h1>
            <div class="section-header-breadcrumb">
                <div class="breadcrumb-item active"><a href="{{ url('/dashboard') }}">Dashboard</a></div>
                <div class="breadcrumb-item">Blocked IPs</div>
            </div>
        </div>

        <div class="section-body">
            <!-- Alert Messages -->
            @if(Session::has('success'))
                <div class="alert alert-success alert-dismissible show fade">
                    <div class="alert-body">
                        <button class="close" data-dismiss="alert">
                            <span>&times;</span>
                        </button>
                        {{ Session::get('success') }}
                    </div>
                </div>
            @endif

            @if(Session::has('error'))
                <div class="alert alert-danger alert-dismissible show fade">
                    <div class="alert-body">
                        <button class="close" data-dismiss="alert">
                            <span>&times;</span>
                        </button>
                        {{ Session::get('error') }}
                    </div>
                </div>
            @endif

            <!-- Action Buttons -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Quick Actions</h4>
                        </div>
                        <div class="card-body">
                            <div class="d-flex flex-wrap">
                                <button class="btn btn-primary mr-2 mb-2" data-toggle="modal" data-target="#blockIpModal">
                                    <i class="fas fa-ban"></i> Block New IP
                                </button>
                                <a href="{{ route('admin.blocked-ips.export') }}" class="btn btn-success mr-2 mb-2">
                                    <i class="fas fa-download"></i> Export CSV
                                </a>
                                <a href="{{ route('admin.blocked-ips.cleanup') }}" class="btn btn-warning mr-2 mb-2" 
                                   onclick="return confirm('This will clean up all expired IP blocks. Continue?')">
                                    <i class="fas fa-broom"></i> Cleanup Expired
                                </a>
                                <button class="btn btn-info mb-2" onclick="location.reload()">
                                    <i class="fas fa-sync"></i> Refresh
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Statistics Cards -->
            <div class="row">
                <div class="col-lg-3 col-md-6 col-sm-6 col-12">
                    <div class="card card-statistic-1">
                        <div class="card-icon bg-primary">
                            <i class="fas fa-shield-alt"></i>
                        </div>
                        <div class="card-wrap">
                            <div class="card-header">
                                <h4>Total Blocks</h4>
                            </div>
                            <div class="card-body">
                                {{ $stats['total'] }}
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 col-sm-6 col-12">
                    <div class="card card-statistic-1">
                        <div class="card-icon bg-danger">
                            <i class="fas fa-ban"></i>
                        </div>
                        <div class="card-wrap">
                            <div class="card-header">
                                <h4>Active Blocks</h4>
                            </div>
                            <div class="card-body">
                                {{ $stats['active'] }}
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 col-sm-6 col-12">
                    <div class="card card-statistic-1">
                        <div class="card-icon bg-warning">
                            <i class="fas fa-clock"></i>
                        </div>
                        <div class="card-wrap">
                            <div class="card-header">
                                <h4>Temporary</h4>
                            </div>
                            <div class="card-body">
                                {{ $stats['temporary'] }}
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 col-sm-6 col-12">
                    <div class="card card-statistic-1">
                        <div class="card-icon bg-dark">
                            <i class="fas fa-lock"></i>
                        </div>
                        <div class="card-wrap">
                            <div class="card-header">
                                <h4>Permanent</h4>
                            </div>
                            <div class="card-body">
                                {{ $stats['permanent'] }}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Blocked IPs Table -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Blocked IP Addresses</h4>
                            <div class="card-header-action">
                                <small class="text-muted">Total: {{ $blockedIps->total() }} records</small>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>IP Address</th>
                                            <th>Reason</th>
                                            <th>Blocked By</th>
                                            <th>Status</th>
                                            <th>Expires At</th>
                                            <th>Created At</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($blockedIps as $ip)
                                        <tr>
                                            <td>
                                                <strong class="text-primary">{{ $ip->ip_address }}</strong>
                                                <br>
                                                <small class="text-muted">
                                                    <a href="{{ route('admin.blocked-ips.show', $ip->ip_address) }}" class="text-muted">
                                                        <i class="fas fa-info-circle"></i> View Details
                                                    </a>
                                                </small>
                                            </td>
                                            <td>
                                                <span class="text-truncate" style="max-width: 200px; display: inline-block;" 
                                                      title="{{ $ip->reason }}">
                                                    {{ $ip->reason }}
                                                </span>
                                            </td>
                                            <td>
                                                @if($ip->blockedBy)
                                                    <i class="fas fa-user"></i> {{ $ip->blockedBy->admin_name }}
                                                @else
                                                    <i class="fas fa-robot"></i> <span class="text-muted">System</span>
                                                @endif
                                            </td>
                                            <td>
                                                @if($ip->is_active)
                                                    @if($ip->isPermanent())
                                                        <span class="badge badge-danger">
                                                            <i class="fas fa-infinity"></i> Permanent
                                                        </span>
                                                    @elseif($ip->isExpired())
                                                        <span class="badge badge-warning">
                                                            <i class="fas fa-hourglass-end"></i> Expired
                                                        </span>
                                                    @else
                                                        <span class="badge badge-danger">
                                                            <i class="fas fa-ban"></i> Active
                                                        </span>
                                                    @endif
                                                @else
                                                    <span class="badge badge-secondary">
                                                        <i class="fas fa-check"></i> Inactive
                                                    </span>
                                                @endif
                                            </td>
                                            <td>
                                                @if($ip->expires_at)
                                                    <small>{{ $ip->expires_at->format('Y-m-d H:i') }}</small>
                                                    <br>
                                                    <small class="text-muted">{{ $ip->getRemainingTime() }}</small>
                                                @else
                                                    <span class="text-muted">
                                                        <i class="fas fa-infinity"></i> Never
                                                    </span>
                                                @endif
                                            </td>
                                            <td>
                                                <small>{{ $ip->created_at->format('Y-m-d H:i') }}</small>
                                                <br>
                                                <small class="text-muted">{{ $ip->created_at->diffForHumans() }}</small>
                                            </td>
                                            <td>
                                                <div class="dropdown">
                                                    <a href="#" data-toggle="dropdown" class="btn btn-primary dropdown-toggle btn-sm">
                                                        Actions
                                                    </a>
                                                    <div class="dropdown-menu">
                                                        <a href="{{ route('admin.blocked-ips.show', $ip->ip_address) }}" 
                                                           class="dropdown-item">
                                                            <i class="fas fa-eye"></i> View Details
                                                        </a>
                                                        @if($ip->is_active && !$ip->isExpired())
                                                            <a href="{{ route('admin.blocked-ips.unblock', $ip->id) }}" 
                                                               class="dropdown-item text-success"
                                                               onclick="return confirm('Are you sure you want to unblock this IP?')">
                                                                <i class="fas fa-unlock"></i> Unblock
                                                            </a>
                                                        @endif
                                                        <div class="dropdown-divider"></div>
                                                        <a href="#" class="dropdown-item text-danger" 
                                                           onclick="blockIpFromList('{{ $ip->ip_address }}')">
                                                            <i class="fas fa-ban"></i> Block Again
                                                        </a>
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                        @empty
                                        <tr>
                                            <td colspan="7" class="text-center text-muted">
                                                <div class="empty-state" style="padding: 40px;">
                                                    <i class="fas fa-shield-alt fa-3x mb-3 text-muted"></i>
                                                    <h5>No blocked IPs found</h5>
                                                    <p>You haven't blocked any IP addresses yet. Click "Block New IP" to get started.</p>
                                                </div>
                                            </td>
                                        </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                            
                            <!-- Pagination -->
                            @if($blockedIps->hasPages())
                                <div class="card-footer text-center">
                                    {{ $blockedIps->links() }}
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>

<!-- Block IP Modal -->
<div class="modal fade" id="blockIpModal" tabindex="-1" role="dialog" aria-labelledby="blockIpModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="blockIpModalLabel">
                    <i class="fas fa-ban text-danger"></i> Block IP Address
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form action="{{ route('admin.blocked-ips.store') }}" method="POST">
                @csrf
                <div class="modal-body">
                    <div class="form-group">
                        <label for="ip_address">IP Address <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="ip_address" name="ip_address" required 
                               placeholder="192.168.1.100" pattern="^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$">
                        <small class="form-text text-muted">Enter a valid IPv4 address</small>
                    </div>
                    <div class="form-group">
                        <label for="reason">Reason <span class="text-danger">*</span></label>
                        <textarea class="form-control" id="reason" name="reason" rows="3" required 
                                  placeholder="Enter reason for blocking this IP"></textarea>
                    </div>
                    <div class="form-group">
                        <label for="block_type">Block Type <span class="text-danger">*</span></label>
                        <select class="form-control" id="block_type" name="block_type" required>
                            <option value="">Select block type</option>
                            <option value="temporary">Temporary Block</option>
                            <option value="permanent">Permanent Block</option>
                        </select>
                    </div>
                    <div class="form-group" id="duration_field" style="display: none;">
                        <label for="duration">Duration (hours) <span class="text-danger">*</span></label>
                        <select class="form-control" id="duration" name="duration">
                            <option value="1">1 Hour</option>
                            <option value="6">6 Hours</option>
                            <option value="24" selected>24 Hours (1 Day)</option>
                            <option value="168">168 Hours (1 Week)</option>
                            <option value="720">720 Hours (1 Month)</option>
                            <option value="8760">8760 Hours (1 Year)</option>
                        </select>
                        <small class="form-text text-muted">Select how long this IP should be blocked</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-danger">
                        <i class="fas fa-ban"></i> Block IP
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const blockTypeSelect = document.getElementById('block_type');
    const durationField = document.getElementById('duration_field');
    
    blockTypeSelect.addEventListener('change', function() {
        if (this.value === 'permanent') {
            durationField.style.display = 'none';
            document.getElementById('duration').removeAttribute('required');
        } else if (this.value === 'temporary') {
            durationField.style.display = 'block';
            document.getElementById('duration').setAttribute('required', 'required');
        }
    });
});

function blockIpFromList(ip) {
    document.getElementById('ip_address').value = ip;
    $('#blockIpModal').modal('show');
}

// Auto-dismiss alerts after 5 seconds
setTimeout(function() {
    $('.alert').fadeOut('slow');
}, 5000);
</script>
@endsection 