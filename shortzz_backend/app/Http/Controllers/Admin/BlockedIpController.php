<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Redirect;
use Session;
use DB;
use Carbon\Carbon;
use App\BlockedIp;
use App\User;
use App\Transaction;
use App\Post;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class BlockedIpController extends Controller
{
    public function __construct()
    {
        // Check if admin is logged in
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }
    }

    /**
     * Display list of blocked IPs
     */
    public function index()
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        // Clean up expired blocks first
        BlockedIp::cleanupExpiredBlocks();

        $blockedIps = BlockedIp::with('blockedBy')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        $stats = BlockedIp::getBlockStats();

        return view('admin.blocked_ips.index', compact('blockedIps', 'stats'));
    }

    /**
     * Show form to block an IP
     */
    public function create()
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        return view('admin.blocked_ips.create');
    }

    /**
     * Store a new blocked IP
     */
    public function store(Request $request)
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        $request->validate([
            'ip_address' => 'required|ip',
            'reason' => 'required|string|max:255',
            'block_type' => 'required|in:permanent,temporary',
            'duration' => 'required_if:block_type,temporary|integer|min:1|max:8760', // Max 1 year in hours
        ]);

        $expiresAt = null;
        if ($request->block_type === 'temporary') {
            $expiresAt = now()->addHours($request->duration);
        }

        try {
            BlockedIp::blockIp(
                $request->ip_address,
                $request->reason,
                Session::get('admin_id'),
                $expiresAt
            );

            // Also block in cache for immediate effect
            if ($request->block_type === 'temporary') {
                Cache::put("blocked_ip:{$request->ip_address}", true, $request->duration * 3600);
            } else {
                Cache::put("blocked_ip:{$request->ip_address}", true, now()->addYears(10));
            }

            Log::info("IP blocked by admin", [
                'ip_address' => $request->ip_address,
                'reason' => $request->reason,
                'block_type' => $request->block_type,
                'blocked_by' => Session::get('admin_id'),
                'expires_at' => $expiresAt
            ]);

            Session::flash('success', 'IP address has been blocked successfully!');
            return redirect()->route('admin.blocked-ips.index');

        } catch (\Exception $e) {
            Log::error("Error blocking IP: " . $e->getMessage());
            Session::flash('error', 'Failed to block IP address. Please try again.');
            return back()->withInput();
        }
    }

    /**
     * Show IP details and activity
     */
    public function show($ip)
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        $blockHistory = BlockedIp::getIpHistory($ip);
        $userActivity = $this->getUserActivityByIp($ip);
        $securityEvents = $this->getSecurityEventsByIp($ip);

        return view('admin.blocked_ips.show', compact('ip', 'blockHistory', 'userActivity', 'securityEvents'));
    }

    /**
     * Unblock an IP
     */
    public function unblock($id)
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        try {
            $blockedIp = BlockedIp::findOrFail($id);
            $ip = $blockedIp->ip_address;

            // Unblock in database
            $blockedIp->update(['is_active' => false]);

            // Remove from cache
            Cache::forget("blocked_ip:{$ip}");

            Log::info("IP unblocked by admin", [
                'ip_address' => $ip,
                'unblocked_by' => Session::get('admin_id'),
                'original_block_id' => $id
            ]);

            Session::flash('success', 'IP address has been unblocked successfully!');
            return redirect()->route('admin.blocked-ips.index');

        } catch (\Exception $e) {
            Log::error("Error unblocking IP: " . $e->getMessage());
            Session::flash('error', 'Failed to unblock IP address. Please try again.');
            return back();
        }
    }

    /**
     * Block IP via AJAX
     */
    public function blockIpAjax(Request $request)
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'ip_address' => 'required|ip',
            'reason' => 'required|string|max:255',
            'block_type' => 'required|in:permanent,temporary',
            'duration' => 'required_if:block_type,temporary|integer|min:1|max:8760',
        ]);

        $expiresAt = null;
        if ($request->block_type === 'temporary') {
            $expiresAt = now()->addHours($request->duration);
        }

        try {
            BlockedIp::blockIp(
                $request->ip_address,
                $request->reason,
                Session::get('admin_id'),
                $expiresAt
            );

            return response()->json([
                'success' => true,
                'message' => 'IP address blocked successfully!'
            ]);

        } catch (\Exception $e) {
            Log::error("Error blocking IP via AJAX: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to block IP address'
            ], 500);
        }
    }

    /**
     * Unblock IP via AJAX
     */
    public function unblockIpAjax(Request $request)
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'ip_address' => 'required|ip',
        ]);

        try {
            BlockedIp::unblockIp($request->ip_address);
            Cache::forget("blocked_ip:{$request->ip_address}");

            return response()->json([
                'success' => true,
                'message' => 'IP address unblocked successfully!'
            ]);

        } catch (\Exception $e) {
            Log::error("Error unblocking IP via AJAX: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to unblock IP address'
            ], 500);
        }
    }

    /**
     * Get user activity by IP address
     */
    private function getUserActivityByIp($ip)
    {
        // Get users who have used this IP
        $users = User::where('last_login_ip', $ip)
            ->orWhere('known_ips', 'like', "%{$ip}%")
            ->with(['posts' => function($query) {
                $query->latest()->take(5);
            }])
            ->get();

        // Get recent transactions from this IP
        $transactions = Transaction::where('created_at', '>=', now()->subDays(30))
            ->orderBy('created_at', 'desc')
            ->take(20)
            ->get();

        // Get recent posts from this IP (if we track IP in posts table)
        $posts = Post::where('created_at', '>=', now()->subDays(30))
            ->orderBy('created_at', 'desc')
            ->take(10)
            ->get();

        return [
            'users' => $users,
            'transactions' => $transactions,
            'posts' => $posts,
            'total_users' => $users->count(),
            'total_transactions' => $transactions->count(),
            'total_posts' => $posts->count()
        ];
    }

    /**
     * Get security events by IP address
     */
    private function getSecurityEventsByIp($ip)
    {
        // This would typically come from your security logs
        // For now, we'll return sample data structure
        return [
            'failed_logins' => 0,
            'suspicious_activities' => 0,
            'rate_limit_violations' => 0,
            'fraud_attempts' => 0,
            'last_activity' => null
        ];
    }

    /**
     * Export blocked IPs to CSV
     */
    public function export()
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        $blockedIps = BlockedIp::with('blockedBy')->get();

        $csvData = [];
        $csvData[] = ['IP Address', 'Reason', 'Blocked By', 'Status', 'Expires At', 'Created At'];

        foreach ($blockedIps as $ip) {
            $csvData[] = [
                $ip->ip_address,
                $ip->reason,
                $ip->blockedBy ? $ip->blockedBy->admin_name : 'System',
                $ip->is_active ? 'Active' : 'Inactive',
                $ip->expires_at ? $ip->expires_at->format('Y-m-d H:i:s') : 'Permanent',
                $ip->created_at->format('Y-m-d H:i:s')
            ];
        }

        $filename = 'blocked_ips_' . now()->format('Y-m-d_H-i-s') . '.csv';
        $filePath = storage_path('app/public/' . $filename);

        $file = fopen($filePath, 'w');
        foreach ($csvData as $row) {
            fputcsv($file, $row);
        }
        fclose($file);

        return response()->download($filePath, $filename)->deleteFileAfterSend();
    }

    /**
     * Clean up expired blocks
     */
    public function cleanup()
    {
        if (!Session::get('name') || Session::get('is_logged') != 1) {
            return redirect()->route('admin.login');
        }

        $cleaned = BlockedIp::cleanupExpiredBlocks();

        Session::flash('success', "Cleaned up {$cleaned} expired IP blocks!");
        return redirect()->route('admin.blocked-ips.index');
    }
} 