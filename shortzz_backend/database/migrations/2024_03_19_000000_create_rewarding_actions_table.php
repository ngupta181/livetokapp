<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRewardingActionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Since the table already exists, we'll check if it doesn't exist first
        if (!Schema::hasTable('tbl_rewarding_action')) {
            Schema::create('tbl_rewarding_action', function (Blueprint $table) {
                $table->id();
                $table->string('action_name');
                $table->integer('coin')->default(0);
                $table->boolean('status')->default(true);
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_rewarding_action');
    }
} 