@extends('admin_layouts/main')
@section('pageSpecificCss')
<link href="{{asset('assets/bundles/datatables/datatables.min.css')}}" rel="stylesheet">
<link href="{{asset('assets/bundles/datatables/DataTables-1.10.16/css/dataTables.bootstrap4.min.css')}}" rel="stylesheet">
@stop
@section('content')
<section class="section">
  <div class="section-body">
      <div class="row">
        <div class="col-12">
          <div class="card">
            <div class="card-header">
              <h4>Rewarding Action List (<span class="total_rewarding_action">{{$total_rewarding_action}}</span>)</h4>
              <div class="card-header-form">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#updateRewardingActionModal">
                  <i class="fas fa-plus"></i> Add New Action
                </button>
              </div>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                  <table class="table table-striped" id="rewarding-listing">
                    <thead>
                      <tr>
                        <th>Action Name</th>
                        <th>Coin</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                    </tbody>
                  </table>
              </div>
            </div>
        </div>
    </div>
  </div>
</section>

<div class="modal fade" id="updateRewardingActionModal" tabindex="-1" role="dialog" aria-labelledby="rewardingActionModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="rewardingActionModalLabel">Add Rewarding Action</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="updateRewardingAction" method="post">
                    @csrf
                    <input type="hidden" name="rewarding_action_id" id="rewarding_action_id" value="">
                    
                    <div class="form-group">
                        <label for="action_name">Action Name</label>
                        <input type="text" class="form-control" id="action_name" name="action_name" placeholder="Enter action name" required>
                    </div>

                    <div class="form-group">
                        <label for="coin">Coin</label>
                        <input type="number" class="form-control" id="coin" name="coin" placeholder="Enter coin value" required min="0">
                    </div>

                    <div class="form-group">
                        <label for="status">Status</label>
                        <select class="form-control" id="status" name="status">
                            <option value="1">Active</option>
                            <option value="0">Inactive</option>
                        </select>
                    </div>

                    <div class="form-group text-right mb-0">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="modal fade" id="deleteConfirmationModal" tabindex="-1" role="dialog" aria-labelledby="deleteConfirmationModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="deleteConfirmationModalLabel">Confirm Delete</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                Are you sure you want to delete this rewarding action?
                <input type="hidden" id="delete_action_id">
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-danger" id="confirmDelete">Delete</button>
            </div>
        </div>
    </div>
</div>
@endsection

@section('pageSpecificJs')
<script src="{{asset('assets/bundles/datatables/datatables.min.js')}}"></script>
<script src="{{asset('assets/bundles/datatables/DataTables-1.10.16/js/dataTables.bootstrap4.min.js')}}"></script>
<script src="{{asset('assets/bundles/jquery-ui/jquery-ui.min.js')}}"></script>
<script src="{{asset('assets/js/page/datatables.js')}}"></script>
<script src="{{asset('assets/bundles/izitoast/js/iziToast.min.js')}}"></script>

<script>
$(document).ready(function() {
    var dataTable = $('#rewarding-listing').DataTable({
        'processing': true,
        'serverSide': true,
        'serverMethod': 'post',
        "order": [[ 0, "desc" ]],
        'columnDefs': [ {
            'targets': [2,3], /* column index */
            'orderable': false, /* true or false */
        }],
        'ajax': {
            'url': '{{ route("showRewardingActionList") }}',
            'data': function(data) {
                // Additional data if needed
            }
        },
        columns: [
            { data: 'action_name' },
            { data: 'coin' },
            { 
                data: 'status',
                render: function(data) {
                    return data == 1 ? 
                        '<span class="badge badge-success">Active</span>' : 
                        '<span class="badge badge-danger">Inactive</span>';
                }
            },
            { 
                data: null,
                render: function(data, type, row) {
                    return `
                        <button class="btn btn-sm btn-info editAction" data-id="${row.rewarding_action_id}" data-name="${row.action_name}" data-coin="${row.coin}" data-status="${row.status}">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger deleteAction" data-id="${row.rewarding_action_id}">
                            <i class="fas fa-trash"></i>
                        </button>
                    `;
                }
            }
        ]
    });

    // Reset form when modal is closed
    $('#updateRewardingActionModal').on('hidden.bs.modal', function() {
        $('#updateRewardingAction')[0].reset();
        $('#rewarding_action_id').val('');
        $('.modal-title').text('Add Rewarding Action');
        var validator = $("#updateRewardingAction").validate();
        validator.resetForm();
    });

    // Edit action
    $(document).on('click', '.editAction', function() {
        var id = $(this).data('id');
        var name = $(this).data('name');
        var coin = $(this).data('coin');
        var status = $(this).data('status');

        $('#rewarding_action_id').val(id);
        $('#action_name').val(name);
        $('#coin').val(coin);
        $('#status').val(status);
        $('.modal-title').text('Edit Rewarding Action');
        $('#updateRewardingActionModal').modal('show');
    });

    // Delete action
    $(document).on('click', '.deleteAction', function() {
        var id = $(this).data('id');
        $('#delete_action_id').val(id);
        $('#deleteConfirmationModal').modal('show');
    });

    // Confirm delete
    $('#confirmDelete').click(function() {
        var id = $('#delete_action_id').val();
        $.ajax({
            url: '{{ route("deleteRewardingAction") }}',
            type: 'POST',
            data: {
                id: id,
                _token: '{{ csrf_token() }}'
            },
            success: function(response) {
                $('#deleteConfirmationModal').modal('hide');
                if (response.success) {
                    dataTable.ajax.reload();
                    $('.total_rewarding_action').text(response.total_rewarding_action);
                    iziToast.success({
                        title: 'Success',
                        message: response.message,
                        position: 'topRight'
                    });
                } else {
                    iziToast.error({
                        title: 'Error',
                        message: response.message,
                        position: 'topRight'
                    });
                }
            }
        });
    });

    // Form validation and submission
    $("#updateRewardingAction").validate({
        rules: {
            action_name: {
                required: true,
                minlength: 3
            },
            coin: {
                required: true,
                min: 0,
                number: true
            }
        },
        messages: {
            action_name: {
                required: "Please enter action name",
                minlength: "Action name must be at least 3 characters"
            },
            coin: {
                required: "Please enter coin value",
                min: "Coin value must be 0 or greater",
                number: "Please enter a valid number"
            }
        },
        submitHandler: function(form) {
            var formData = new FormData(form);
            $.ajax({
                url: '{{ route("updateRewardingAction") }}',
                type: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                success: function(response) {
                    $('#updateRewardingActionModal').modal('hide');
                    if (response.success) {
                        dataTable.ajax.reload();
                        $('.total_rewarding_action').text(response.total_rewarding_action);
                        iziToast.success({
                            title: 'Success',
                            message: response.message,
                            position: 'topRight'
                        });
                    } else {
                        iziToast.error({
                            title: 'Error',
                            message: response.message,
                            position: 'topRight'
                        });
                    }
                }
            });
            return false;
        }
    });
});
</script>
@endsection
