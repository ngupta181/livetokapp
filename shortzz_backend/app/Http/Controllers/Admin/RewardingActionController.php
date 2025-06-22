<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use App\RewardingAction;
use Session;
use DB;

class RewardingActionController extends Controller
{
    public function viewListRewardingAction()
    {
        $total_rewarding_action = RewardingAction::count();
        return view('admin.rewarding_action.rewarding_action_list', compact('total_rewarding_action'));
    }

    public function showRewardingActionList(Request $request)
    {
        $columns = array(
            0 => 'action_name',
            1 => 'coin',
            2 => 'status',
            3 => 'rewarding_action_id'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');

        $totalData = RewardingAction::count();
        $totalFiltered = $totalData;

        if (empty($request->input('search.value'))) {
            $actions = RewardingAction::offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');

            $actions = RewardingAction::where('action_name', 'LIKE', "%{$search}%")
                ->orWhere('coin', 'LIKE', "%{$search}%")
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();

            $totalFiltered = RewardingAction::where('action_name', 'LIKE', "%{$search}%")
                ->orWhere('coin', 'LIKE', "%{$search}%")
                ->count();
        }

        $data = array();
        if (!empty($actions)) {
            foreach ($actions as $action) {
                $nestedData['rewarding_action_id'] = $action->rewarding_action_id;
                $nestedData['action_name'] = $action->action_name;
                $nestedData['coin'] = $action->coin;
                $nestedData['status'] = $action->status;

                $data[] = $nestedData;
            }
        }

        $json_data = array(
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data
        );

        return response()->json($json_data);
    }

    public function updateRewardingAction(Request $request)
    {
        try {
            $request->validate([
                'action_name' => 'required|min:3',
                'coin' => 'required|numeric|min:0',
                'status' => 'required|boolean'
            ]);

            $action = RewardingAction::updateOrCreate(
                ['rewarding_action_id' => $request->rewarding_action_id],
                [
                    'action_name' => $request->action_name,
                    'coin' => $request->coin,
                    'status' => $request->status
                ]
            );

            $total_rewarding_action = RewardingAction::count();

            return response()->json([
                'success' => true,
                'message' => $request->rewarding_action_id ? 'Rewarding action updated successfully' : 'Rewarding action added successfully',
                'total_rewarding_action' => $total_rewarding_action
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Something went wrong: ' . $e->getMessage()
            ]);
        }
    }

    public function deleteRewardingAction(Request $request)
    {
        try {
            $request->validate([
                'id' => 'required|exists:tbl_rewarding_action,rewarding_action_id'
            ]);

            RewardingAction::where('rewarding_action_id', $request->id)->delete();
            
            $total_rewarding_action = RewardingAction::count();

            return response()->json([
                'success' => true,
                'message' => 'Rewarding action deleted successfully',
                'total_rewarding_action' => $total_rewarding_action
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Something went wrong: ' . $e->getMessage()
            ]);
        }
    }
}
