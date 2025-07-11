<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddSecurityFieldsToUsersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            // Security flags
            $table->boolean('is_blocked')->default(false)->after('is_notification');
            $table->timestamp('blocked_at')->nullable()->after('is_blocked');
            $table->string('blocked_reason')->nullable()->after('blocked_at');
            
            // Fraud detection tracking
            $table->integer('failed_login_attempts')->default(0)->after('blocked_reason');
            $table->timestamp('last_failed_login')->nullable()->after('failed_login_attempts');
            $table->integer('suspicious_activity_count')->default(0)->after('last_failed_login');
            $table->timestamp('last_suspicious_activity')->nullable()->after('suspicious_activity_count');
            
            // IP and device tracking
            $table->string('last_login_ip')->nullable()->after('last_suspicious_activity');
            $table->json('known_ips')->nullable()->after('last_login_ip');
            $table->string('last_user_agent')->nullable()->after('known_ips');
            
            // Wallet security tracking
            $table->integer('failed_transactions')->default(0)->after('last_user_agent');
            $table->timestamp('last_failed_transaction')->nullable()->after('failed_transactions');
            $table->decimal('total_earned_coins', 10, 2)->default(0)->after('last_failed_transaction');
            $table->decimal('total_spent_coins', 10, 2)->default(0)->after('total_earned_coins');
            $table->timestamp('last_wallet_activity')->nullable()->after('total_spent_coins');
            
            // Security verification
            $table->boolean('is_verified_user')->default(false)->after('last_wallet_activity');
            $table->integer('trust_score')->default(50)->after('is_verified_user'); // 0-100 scale
            
            // Indexes for performance
            $table->index(['is_blocked', 'blocked_at']);
            $table->index(['last_login_ip']);
            $table->index(['suspicious_activity_count', 'last_suspicious_activity']);
            $table->index(['trust_score']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['is_blocked', 'blocked_at']);
            $table->dropIndex(['last_login_ip']);
            $table->dropIndex(['suspicious_activity_count', 'last_suspicious_activity']);
            $table->dropIndex(['trust_score']);
            
            $table->dropColumn([
                'is_blocked',
                'blocked_at',
                'blocked_reason',
                'failed_login_attempts',
                'last_failed_login',
                'suspicious_activity_count',
                'last_suspicious_activity',
                'last_login_ip',
                'known_ips',
                'last_user_agent',
                'failed_transactions',
                'last_failed_transaction',
                'total_earned_coins',
                'total_spent_coins',
                'last_wallet_activity',
                'is_verified_user',
                'trust_score'
            ]);
        });
    }
} 