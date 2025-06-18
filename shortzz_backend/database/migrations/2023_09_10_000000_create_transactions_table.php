<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_transactions', function (Blueprint $table) {
            $table->bigIncrements('transaction_id');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('to_user_id')->nullable();
            $table->string('transaction_type')->comment('purchase, gift, redeem, reward');
            $table->integer('coins')->default(0)->comment('Number of coins');
            $table->decimal('amount', 10, 2)->default(0)->comment('Transaction amount in currency');
            $table->string('payment_method')->nullable()->comment('Payment method for purchases');
            $table->string('transaction_reference')->nullable()->comment('Payment gateway reference ID');
            $table->string('platform')->nullable()->comment('ios, android, web');
            $table->string('gift_id')->nullable()->comment('Reference to gift if transaction_type is gift');
            $table->string('status')->default('completed')->comment('pending, completed, failed');
            $table->text('meta_data')->nullable()->comment('Additional transaction data in JSON');
            $table->timestamps();
            
            // Add indexes for faster queries
            $table->index('user_id');
            $table->index('to_user_id');
            $table->index('transaction_type');
            $table->index('status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_transactions');
    }
} 