<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class CheckIpStatus extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'security:check-ip {ip : The IP address to check}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check the security status of an IP address';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $ip = $this->argument('ip');
        
        $this->info("🔍 Security Status for IP: {$ip}");
        $this->line("=" . str_repeat("=", 50));
        
        // Check if IP is blocked
        $blockKey = "blocked_ip:{$ip}";
        $isBlocked = Cache::has($blockKey);
        
        if ($isBlocked) {
            $this->error("🚫 Status: BLOCKED (Temporary)");
            $blockTtl = Cache::get($blockKey) ? "Active" : "Expired";
            $this->line("   Block TTL: {$blockTtl}");
        } else {
            $this->info("✅ Status: NOT BLOCKED");
        }
        
        // Check whitelist status
        $whitelist = config('wallet_security.ip_blocking.whitelist', []);
        $isWhitelisted = in_array($ip, $whitelist);
        
        if ($isWhitelisted) {
            $this->info("🛡️  Whitelist: YES (Always allowed)");
        } else {
            $this->line("🛡️  Whitelist: NO");
        }
        
        // Check testing mode
        $testingMode = config('wallet_security.ip_blocking.testing_mode.enabled', false);
        $testingIps = config('wallet_security.ip_blocking.testing_mode.allowed_ips', []);
        $isTestingIp = in_array($ip, $testingIps);
        
        if ($testingMode && $isTestingIp) {
            $this->info("🧪 Testing Mode: YES (Security bypassed)");
        } else {
            $this->line("🧪 Testing Mode: " . ($testingMode ? "Enabled but IP not in list" : "Disabled"));
        }
        
        // Check permanent blocks
        $permanentBlocks = config('wallet_security.ip_blocking.permanent_blocks', []);
        $isPermanentBlocked = in_array($ip, $permanentBlocks);
        
        if ($isPermanentBlocked) {
            $this->error("🔒 Permanent Block: YES (Fraud IP)");
        } else {
            $this->line("🔒 Permanent Block: NO");
        }
        
        // Check current rate limits
        $currentRate = Cache::get("global_rate:{$ip}:" . now()->format('Y-m-d-H-i'), 0);
        $maxRate = config('wallet_security.rate_limits.global_requests.max_attempts', 100);
        
        $this->line("📊 Current Rate: {$currentRate}/{$maxRate} requests this minute");
        
        if ($currentRate > $maxRate * 0.8) {
            $this->warn("⚠️  High rate usage detected!");
        }
        
        // Overall status
        $this->line("=" . str_repeat("=", 50));
        
        $canAccess = !$isBlocked && !$isPermanentBlocked;
        $bypassesSecurity = $isWhitelisted || ($testingMode && $isTestingIp);
        
        if ($bypassesSecurity) {
            $this->info("🎯 FINAL STATUS: FULL ACCESS (Security bypassed)");
        } elseif ($canAccess) {
            $this->info("🎯 FINAL STATUS: ALLOWED (Subject to security checks)");
        } else {
            $this->error("🎯 FINAL STATUS: BLOCKED");
        }
        
        return 0;
    }
} 