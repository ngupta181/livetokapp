<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCommentLikesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_comment_likes', function (Blueprint $table) {
            $table->increments('like_id');
            $table->integer('comments_id');
            $table->integer('user_id');
            $table->timestamps();
            
            // Add unique constraint to prevent duplicate likes
            $table->unique(['comments_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_comment_likes');
    }
}
