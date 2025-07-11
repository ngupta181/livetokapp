<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class UnblockIp extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'security:unblock-ip {ip : The IP address to unblock}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Unblock a temporarily blocked IP address';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $ip = $this->argument('ip');
        
        // Remove IP from temporary block cache
        $blockKey = "blocked_ip:{$ip}";
        $wasBlocked = Cache::has($blockKey);
        
        if ($wasBlocked) {
            Cache::forget($blockKey);
            $this->info("✅ IP {$ip} has been unblocked successfully!");
        } else {
            $this->warn("⚠️  IP {$ip} was not blocked.");
        }
        
        // Also clear rate limiting caches for this IP
        $rateLimitKeys = [
            "global_rate:{$ip}:" . now()->format('Y-m-d-H-i'),
            "global_rate:{$ip}:" . now()->subMinutes(1)->format('Y-m-d-H-i'),
            "global_rate:{$ip}:" . now()->subMinutes(2)->format('Y-m-d-H-i'),
        ];
        
        foreach ($rateLimitKeys as $key) {
            Cache::forget($key);
        }
        
        $this->info("✅ Rate limiting cache cleared for IP {$ip}");
        
        // Show current status
        $this->info("📊 Current Status:");
        $this->line("- IP: {$ip}");
        $this->line("- Blocked: " . (Cache::has($blockKey) ? "Yes" : "No"));
        $this->line("- Current Rate Count: " . Cache::get("global_rate:{$ip}:" . now()->format('Y-m-d-H-i'), 0));
        
        return 0;
    }
} 