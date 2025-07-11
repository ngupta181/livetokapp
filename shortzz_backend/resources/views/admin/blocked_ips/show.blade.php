@extends('admin_layouts/main')

@section('content')
<div class="main-content">
    <section class="section">
        <div class="section-header">
            <h1>IP Address Details</h1>
            <div class="section-header-breadcrumb">
                <div class="breadcrumb-item active"><a href="{{ url('/dashboard') }}">Dashboard</a></div>
                <div class="breadcrumb-item active"><a href="{{ url('/blocked-ips/list') }}">Blocked IPs</a></div>
                <div class="breadcrumb-item">{{ $ip }}</div>
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
                            <h4>IP Address: <code class="text-primary">{{ $ip }}</code></h4>
                        </div>
                        <div class="card-body">
                            <div class="d-flex flex-wrap">
                                <a href="{{ route('admin.blocked-ips.index') }}" class="btn btn-secondary mr-2 mb-2">
                                    <i class="fas fa-arrow-left"></i> Back to List
                                </a>
                                <button class="btn btn-danger mr-2 mb-2" onclick="showBlockModal('{{ $ip }}')">
                                    <i class="fas fa-ban"></i> Block This IP
                                </button>
                                @php
                                    $isCurrentlyBlocked = \App\BlockedIp::isBlocked($ip);
                                @endphp
                                @if($isCurrentlyBlocked)
                                    <button class="btn btn-success mr-2 mb-2" onclick="unblockIpAjax('{{ $ip }}')">
                                        <i class="fas fa-unlock"></i> Unblock This IP
                                    </button>
                                @endif
                                <button class="btn btn-info mb-2" onclick="location.reload()">
                                    <i class="fas fa-sync"></i> Refresh
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- IP Information Cards -->
            <div class="row">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fas fa-info-circle"></i> IP Information</h4>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <tr>
                                        <td width="35%"><strong>IP Address:</strong></td>
                                        <td><code class="text-primary">{{ $ip }}</code></td>
                                    </tr>
                                    <tr>
                                        <td><strong>Current Status:</strong></td>
                                        <td>
                                            @if($isCurrentlyBlocked)
                                                <span class="badge badge-danger">
                                                    <i class="fas fa-ban"></i> BLOCKED
                                                </span>
                                            @else
                                                <span class="badge badge-success">
                                                    <i class="fas fa-check"></i> ALLOWED
                                                </span>
                                            @endif
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Total Users:</strong></td>
                                        <td>
                                            <span class="badge badge-info">{{ $userActivity['total_users'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Total Transactions:</strong></td>
                                        <td>
                                            <span class="badge badge-primary">{{ $userActivity['total_transactions'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Total Posts:</strong></td>
                                        <td>
                                            <span class="badge badge-secondary">{{ $userActivity['total_posts'] }}</span>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fas fa-shield-alt"></i> Security Events</h4>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <tr>
                                        <td width="50%"><strong>Failed Logins:</strong></td>
                                        <td>
                                            <span class="badge badge-warning">{{ $securityEvents['failed_logins'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Suspicious Activities:</strong></td>
                                        <td>
                                            <span class="badge badge-danger">{{ $securityEvents['suspicious_activities'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Rate Limit Violations:</strong></td>
                                        <td>
                                            <span class="badge badge-warning">{{ $securityEvents['rate_limit_violations'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td><strong>Fraud Attempts:</strong></td>
                                        <td>
                                            <span class="badge badge-danger">{{ $securityEvents['fraud_attempts'] }}</span>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Block History -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fas fa-history"></i> Block History</h4>
                            <div class="card-header-action">
                                <small class="text-muted">{{ count($blockHistory) }} records</small>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>Reason</th>
                                            <th>Blocked By</th>
                                            <th>Status</th>
                                            <th>Expires At</th>
                                            <th>Created At</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($blockHistory as $block)
                                        <tr>
                                            <td>{{ $block->reason }}</td>
                                            <td>
                                                @if($block->blockedBy)
                                                    <i class="fas fa-user"></i> {{ $block->blockedBy->admin_name }}
                                                @else
                                                    <i class="fas fa-robot"></i> <span class="text-muted">System</span>
                                                @endif
                                            </td>
                                            <td>
                                                @if($block->is_active)
                                                    @if($block->isPermanent())
                                                        <span class="badge badge-danger">
                                                            <i class="fas fa-infinity"></i> Permanent
                                                        </span>
                                                    @elseif($block->isExpired())
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
                                                @if($block->expires_at)
                                                    <small>{{ $block->expires_at->format('Y-m-d H:i') }}</small>
                                                    <br>
                                                    <small class="text-muted">{{ $block->getRemainingTime() }}</small>
                                                @else
                                                    <span class="text-muted">
                                                        <i class="fas fa-infinity"></i> Never
                                                    </span>
                                                @endif
                                            </td>
                                            <td>
                                                <small>{{ $block->created_at->format('Y-m-d H:i') }}</small>
                                                <br>
                                                <small class="text-muted">{{ $block->created_at->diffForHumans() }}</small>
                                            </td>
                                            <td>
                                                @if($block->is_active && !$block->isExpired())
                                                    <a href="{{ route('admin.blocked-ips.unblock', $block->id) }}" 
                                                       class="btn btn-sm btn-success"
                                                       onclick="return confirm('Are you sure you want to unblock this IP?')">
                                                        <i class="fas fa-unlock"></i> Unblock
                                                    </a>
                                                @else
                                                    <span class="text-muted">-</span>
                                                @endif
                                            </td>
                                        </tr>
                                        @empty
                                        <tr>
                                            <td colspan="6" class="text-center text-muted">
                                                <div class="empty-state" style="padding: 20px;">
                                                    <i class="fas fa-history fa-2x mb-2 text-muted"></i>
                                                    <p>No block history found for this IP address</p>
                                                </div>
                                            </td>
                                        </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- User Activity -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fas fa-users"></i> Users from this IP</h4>
                            <div class="card-header-action">
                                <small class="text-muted">{{ count($userActivity['users']) }} users</small>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>User ID</th>
                                            <th>Username</th>
                                            <th>Email</th>
                                            <th>Status</th>
                                            <th>Last Activity</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($userActivity['users'] as $user)
                                        <tr>
                                            <td><strong>{{ $user->user_id }}</strong></td>
                                            <td>{{ $user->user_name }}</td>
                                            <td>{{ $user->email }}</td>
                                            <td>
                                                @if($user->status == 1)
                                                    <span class="badge badge-success">
                                                        <i class="fas fa-check"></i> Active
                                                    </span>
                                                @else
                                                    <span class="badge badge-danger">
                                                        <i class="fas fa-times"></i> Inactive
                                                    </span>
                                                @endif
                                            </td>
                                            <td>
                                                <small>{{ $user->updated_at->format('Y-m-d H:i') }}</small>
                                                <br>
                                                <small class="text-muted">{{ $user->updated_at->diffForHumans() }}</small>
                                            </td>
                                            <td>
                                                <a href="{{ url('/user/view/' . $user->user_id) }}" 
                                                   class="btn btn-sm btn-info">
                                                    <i class="fas fa-eye"></i> View
                                                </a>
                                            </td>
                                        </tr>
                                        @empty
                                        <tr>
                                            <td colspan="6" class="text-center text-muted">
                                                <div class="empty-state" style="padding: 20px;">
                                                    <i class="fas fa-users fa-2x mb-2 text-muted"></i>
                                                    <p>No users found from this IP address</p>
                                                </div>
                                            </td>
                                        </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent Transactions -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fas fa-exchange-alt"></i> Recent Transactions</h4>
                            <div class="card-header-action">
                                <small class="text-muted">Last 30 days - {{ count($userActivity['transactions']) }} records</small>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>Transaction ID</th>
                                            <th>User ID</th>
                                            <th>Type</th>
                                            <th>Amount</th>
                                            <th>Status</th>
                                            <th>Created At</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($userActivity['transactions'] as $transaction)
                                        <tr>
                                            <td><strong>{{ $transaction->id }}</strong></td>
                                            <td>{{ $transaction->user_id }}</td>
                                            <td>
                                                <span class="badge badge-info">{{ $transaction->transaction_type }}</span>
                                            </td>
                                            <td>
                                                @if($transaction->coins)
                                                    <i class="fas fa-coins"></i> {{ $transaction->coins }}
                                                @elseif($transaction->amount)
                                                    <i class="fas fa-dollar-sign"></i> {{ $transaction->amount }}
                                                @else
                                                    -
                                                @endif
                                            </td>
                                            <td>
                                                @if($transaction->status == 'completed')
                                                    <span class="badge badge-success">
                                                        <i class="fas fa-check"></i> Completed
                                                    </span>
                                                @elseif($transaction->status == 'failed')
                                                    <span class="badge badge-danger">
                                                        <i class="fas fa-times"></i> Failed
                                                    </span>
                                                @else
                                                    <span class="badge badge-warning">
                                                        <i class="fas fa-clock"></i> Pending
                                                    </span>
                                                @endif
                                            </td>
                                            <td>
                                                <small>{{ $transaction->created_at->format('Y-m-d H:i') }}</small>
                                                <br>
                                                <small class="text-muted">{{ $transaction->created_at->diffForHumans() }}</small>
                                            </td>
                                        </tr>
                                        @empty
                                        <tr>
                                            <td colspan="6" class="text-center text-muted">
                                                <div class="empty-state" style="padding: 20px;">
                                                    <i class="fas fa-exchange-alt fa-2x mb-2 text-muted"></i>
                                                    <p>No recent transactions found</p>
                                                </div>
                                            </td>
                                        </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
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
            <form id="blockIpForm">
                @csrf
                <div class="modal-body">
                    <div class="form-group">
                        <label for="ip_address">IP Address <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="ip_address" name="ip_address" readonly>
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
function showBlockModal(ip) {
    document.getElementById('ip_address').value = ip;
    $('#blockIpModal').modal('show');
}

function unblockIpAjax(ip) {
    if (confirm('Are you sure you want to unblock this IP address?')) {
        $.post('{{ route("admin.blocked-ips.unblock-ajax") }}', {
            _token: $('[name="_token"]').val(),
            ip_address: ip
        })
        .done(function(data) {
            if (data.success) {
                alert('IP address unblocked successfully!');
                location.reload();
            } else {
                alert('Error: ' + data.message);
            }
        })
        .fail(function() {
            alert('An error occurred while unblocking the IP.');
        });
    }
}

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

    // Handle form submission
    document.getElementById('blockIpForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = new FormData(this);
        
        fetch('{{ route("admin.blocked-ips.block-ajax") }}', {
            method: 'POST',
            body: formData,
            headers: {
                'X-CSRF-TOKEN': document.querySelector('[name="_token"]').value
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert('IP blocked successfully!');
                location.reload();
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('An error occurred while blocking the IP.');
        });
    });
});

// Auto-dismiss alerts after 5 seconds
setTimeout(function() {
    $('.alert').fadeOut('slow');
}, 5000);
</script>
@endsection 