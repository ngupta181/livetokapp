<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUserInteractionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_user_interactions', function (Blueprint $table) {
            $table->bigIncrements('interaction_id');
            $table->integer('user_id');
            $table->integer('post_id');
            $table->enum('interaction_type', ['view', 'like', 'comment', 'share', 'follow', 'skip']);
            $table->integer('duration')->nullable()->comment('Duration in seconds for view interactions');
            $table->timestamps();
            
            // Indexes for faster queries
            $table->index('user_id');
            $table->index('post_id');
            $table->index('interaction_type');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_user_interactions');
    }
}
