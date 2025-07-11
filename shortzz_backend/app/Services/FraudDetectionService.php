<?php

namespace App\Services;

use App\Transaction;
use App\User;
use App\SuspiciousActivity;
use App\BlockedIp;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class FraudDetectionService
{
    private $riskThresholds = [
        'rapid_transactions' => 10, // transactions per 10 minutes
        'high_amount_ratio' => 10, // times higher than average
        'duplicate_ips' => 5, // same IP, different users
        'velocity_threshold' => 5, // purchases per minute
        'amount_threshold' => 100.00, // dollar amount
    ];

    /**
     * Analyze transaction for fraud patterns
     */
    public function analyzeTransaction(Transaction $transaction)
    {
        $riskScore = 0;
        $riskFactors = [];

        // 1. Check transaction velocity
        $velocityRisk = $this->checkTransactionVelocity($transaction);
        $riskScore += $velocityRisk['score'];
        if ($velocityRisk['risk']) {
            $riskFactors[] = $velocityRisk['reason'];
        }

        // 2. Check amount anomalies
        $amountRisk = $this->checkAmountAnomalies($transaction);
        $riskScore += $amountRisk['score'];
        if ($amountRisk['risk']) {
            $riskFactors[] = $amountRisk['reason'];
        }

        // 3. Check IP reputation
        $ipRisk = $this->checkIpReputation($transaction);
        $riskScore += $ipRisk['score'];
        if ($ipRisk['risk']) {
            $riskFactors[] = $ipRisk['reason'];
        }

        // 4. Check user behavior patterns
        $behaviorRisk = $this->checkUserBehavior($transaction);
        $riskScore += $behaviorRisk['score'];
        if ($behaviorRisk['risk']) {
            $riskFactors[] = $behaviorRisk['reason'];
        }

        // 5. Check for payment method anomalies
        $paymentRisk = $this->checkPaymentMethod($transaction);
        $riskScore += $paymentRisk['score'];
        if ($paymentRisk['risk']) {
            $riskFactors[] = $paymentRisk['reason'];
        }

        // Determine risk level
        $riskLevel = $this->calculateRiskLevel($riskScore);

        // Log suspicious activity if risk is medium or higher
        if ($riskLevel !== 'low') {
            $this->logSuspiciousTransaction($transaction, $riskLevel, $riskFactors);
        }

        // Take action based on risk level
        $this->takeAction($transaction, $riskLevel, $riskFactors);

        return [
            'risk_score' => $riskScore,
            'risk_level' => $riskLevel,
            'risk_factors' => $riskFactors,
            'action_taken' => $this->getActionForRiskLevel($riskLevel)
        ];
    }

    /**
     * Check transaction velocity patterns
     */
    private function checkTransactionVelocity(Transaction $transaction)
    {
        $recentTransactions = Transaction::where('user_id', $transaction->user_id)
            ->where('transaction_type', 'purchase')
            ->where('created_at', '>=', now()->subMinutes(10))
            ->count();

        if ($recentTransactions >= $this->riskThresholds['rapid_transactions']) {
            return [
                'risk' => true,
                'score' => 30,
                'reason' => "Rapid transaction pattern detected ({$recentTransactions} purchases in 10 minutes)"
            ];
        }

        // Check for burst patterns (5+ transactions in 1 minute)
        $burstTransactions = Transaction::where('user_id', $transaction->user_id)
            ->where('transaction_type', 'purchase')
            ->where('created_at', '>=', now()->subMinutes(1))
            ->count();

        if ($burstTransactions >= $this->riskThresholds['velocity_threshold']) {
            return [
                'risk' => true,
                'score' => 40,
                'reason' => "High velocity burst detected ({$burstTransactions} purchases in 1 minute)"
            ];
        }

        return ['risk' => false, 'score' => 0, 'reason' => null];
    }

    /**
     * Check for amount anomalies
     */
    private function checkAmountAnomalies(Transaction $transaction)
    {
        // Check if amount is significantly higher than user's average
        $userAvgAmount = Transaction::where('user_id', $transaction->user_id)
            ->where('transaction_type', 'purchase')
            ->avg('amount');

        if ($userAvgAmount && $transaction->amount > ($userAvgAmount * $this->riskThresholds['high_amount_ratio'])) {
            return [
                'risk' => true,
                'score' => 25,
                'reason' => "Amount significantly higher than user average (${$transaction->amount} vs ${$userAvgAmount})"
            ];
        }

        // Check for suspiciously high amounts
        if ($transaction->amount > $this->riskThresholds['amount_threshold']) {
            return [
                'risk' => true,
                'score' => 20,
                'reason' => "High amount transaction (${$transaction->amount})"
            ];
        }

        // Check for zero amounts (major red flag)
        if ($transaction->amount == 0) {
            return [
                'risk' => true,
                'score' => 100,
                'reason' => "Zero amount transaction - potential payment bypass"
            ];
        }

        return ['risk' => false, 'score' => 0, 'reason' => null];
    }

    /**
     * Check IP reputation and patterns
     */
    private function checkIpReputation(Transaction $transaction)
    {
        $metaData = json_decode($transaction->meta_data, true);
        $ip = $metaData['ip_address'] ?? null;

        if (!$ip) {
            return ['risk' => false, 'score' => 0, 'reason' => null];
        }

        // Check if IP is on blocklist
        if (BlockedIp::where('ip_address', $ip)->active()->exists()) {
            return [
                'risk' => true,
                'score' => 50,
                'reason' => "Transaction from blocked IP address"
            ];
        }

        // Check for multiple users from same IP
        $usersFromIp = Transaction::whereJsonContains('meta_data->ip_address', $ip)
            ->distinct('user_id')
            ->count();

        if ($usersFromIp >= $this->riskThresholds['duplicate_ips']) {
            return [
                'risk' => true,
                'score' => 30,
                'reason' => "Multiple users ({$usersFromIp}) from same IP address"
            ];
        }

        return ['risk' => false, 'score' => 0, 'reason' => null];
    }

    /**
     * Check user behavior patterns
     */
    private function checkUserBehavior(Transaction $transaction)
    {
        $user = User::find($transaction->user_id);
        
        if (!$user) {
            return ['risk' => false, 'score' => 0, 'reason' => null];
        }

        // Check if user account is very new
        if ($user->created_at > now()->subHours(24)) {
            return [
                'risk' => true,
                'score' => 20,
                'reason' => "Transaction from new user account (created less than 24 hours ago)"
            ];
        }

        // Check for unusual time patterns
        $hour = now()->hour;
        if ($hour >= 2 && $hour <= 5) { // 2 AM to 5 AM
            return [
                'risk' => true,
                'score' => 10,
                'reason' => "Transaction during unusual hours (2 AM - 5 AM)"
            ];
        }

        return ['risk' => false, 'score' => 0, 'reason' => null];
    }

    /**
     * Check payment method anomalies
     */
    private function checkPaymentMethod(Transaction $transaction)
    {
        // Check for missing transaction reference
        if (empty($transaction->transaction_reference)) {
            return [
                'risk' => true,
                'score' => 40,
                'reason' => "Missing transaction reference"
            ];
        }

        // Check for duplicate transaction references
        $duplicateRefs = Transaction::where('transaction_reference', $transaction->transaction_reference)
            ->where('user_id', '!=', $transaction->user_id)
            ->count();

        if ($duplicateRefs > 0) {
            return [
                'risk' => true,
                'score' => 35,
                'reason' => "Duplicate transaction reference across users"
            ];
        }

        return ['risk' => false, 'score' => 0, 'reason' => null];
    }

    /**
     * Calculate risk level based on score
     */
    private function calculateRiskLevel($score)
    {
        if ($score >= 80) return 'critical';
        if ($score >= 50) return 'high';
        if ($score >= 25) return 'medium';
        return 'low';
    }

    /**
     * Log suspicious transaction
     */
    private function logSuspiciousTransaction(Transaction $transaction, $riskLevel, $riskFactors)
    {
        $metaData = json_decode($transaction->meta_data, true);
        
        SuspiciousActivity::create([
            'user_id' => $transaction->user_id,
            'ip_address' => $metaData['ip_address'] ?? 'unknown',
            'activity_type' => 'suspicious_transaction',
            'details' => [
                'transaction_id' => $transaction->transaction_id,
                'amount' => $transaction->amount,
                'coins' => $transaction->coins,
                'risk_factors' => $riskFactors,
                'transaction_reference' => $transaction->transaction_reference
            ],
            'severity' => $riskLevel
        ]);

        Log::warning("Suspicious transaction detected", [
            'transaction_id' => $transaction->transaction_id,
            'user_id' => $transaction->user_id,
            'risk_level' => $riskLevel,
            'risk_factors' => $riskFactors
        ]);
    }

    /**
     * Take action based on risk level
     */
    private function takeAction(Transaction $transaction, $riskLevel, $riskFactors)
    {
        switch ($riskLevel) {
            case 'critical':
                $this->blockUser($transaction->user_id, $riskFactors);
                $this->blockIp($transaction, $riskFactors);
                $this->flagTransactionForReview($transaction);
                break;
                
            case 'high':
                $this->flagUserForReview($transaction->user_id, $riskFactors);
                $this->flagTransactionForReview($transaction);
                break;
                
            case 'medium':
                $this->flagTransactionForReview($transaction);
                break;
        }
    }

    /**
     * Block user account
     */
    private function blockUser($userId, $reasons)
    {
        // Set user as blocked/suspended
        DB::table('tbl_users')
            ->where('user_id', $userId)
            ->update([
                'is_blocked' => true,
                'blocked_reason' => implode(', ', $reasons),
                'blocked_at' => now()
            ]);

        Log::alert("User blocked due to fraud detection", [
            'user_id' => $userId,
            'reasons' => $reasons
        ]);
    }

    /**
     * Block IP address
     */
    private function blockIp(Transaction $transaction, $reasons)
    {
        $metaData = json_decode($transaction->meta_data, true);
        $ip = $metaData['ip_address'] ?? null;

        if ($ip) {
            BlockedIp::create([
                'ip_address' => $ip,
                'reason' => implode(', ', $reasons),
                'blocked_by' => null, // System blocked
                'is_active' => true,
                'expires_at' => now()->addDays(30)
            ]);

            Log::alert("IP blocked due to fraud detection", [
                'ip' => $ip,
                'reasons' => $reasons
            ]);
        }
    }

    /**
     * Flag transaction for manual review
     */
    private function flagTransactionForReview(Transaction $transaction)
    {
        // Update transaction to require review
        $transaction->update([
            'status' => 'pending_review',
            'meta_data' => json_encode(array_merge(
                json_decode($transaction->meta_data, true) ?? [],
                ['flagged_for_review' => true, 'flagged_at' => now()]
            ))
        ]);
    }

    /**
     * Flag user for review
     */
    private function flagUserForReview($userId, $reasons)
    {
        DB::table('tbl_users')
            ->where('user_id', $userId)
            ->update([
                'requires_review' => true,
                'review_reason' => implode(', ', $reasons),
                'flagged_at' => now()
            ]);
    }

    /**
     * Get action description for risk level
     */
    private function getActionForRiskLevel($riskLevel)
    {
        $actions = [
            'low' => 'No action required',
            'medium' => 'Transaction flagged for review',
            'high' => 'Transaction and user flagged for review',
            'critical' => 'User blocked, IP blocked, transaction flagged'
        ];

        return $actions[$riskLevel] ?? 'Unknown action';
    }

    /**
     * Get fraud statistics
     */
    public function getFraudStatistics($timeframe = 24)
    {
        return [
            'total_suspicious_activities' => SuspiciousActivity::withinHours($timeframe)->count(),
            'critical_activities' => SuspiciousActivity::withinHours($timeframe)->where('severity', 'critical')->count(),
            'high_risk_activities' => SuspiciousActivity::withinHours($timeframe)->where('severity', 'high')->count(),
            'blocked_ips' => BlockedIp::where('created_at', '>=', now()->subHours($timeframe))->count(),
            'flagged_transactions' => Transaction::where('status', 'pending_review')
                ->where('created_at', '>=', now()->subHours($timeframe))
                ->count()
        ];
    }
} 