<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateContentProfilesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_content_profiles', function (Blueprint $table) {
            $table->bigIncrements('content_profile_id');
            $table->integer('post_id')->unique();
            $table->text('extracted_hashtags')->nullable()->comment('JSON array of extracted hashtags');
            $table->text('categories')->nullable()->comment('JSON array of content categories');
            $table->float('engagement_rate')->default(0)->comment('Calculated engagement rate');
            $table->integer('avg_watch_duration')->default(0);
            $table->integer('completion_rate')->default(0)->comment('Percentage of users who watch to the end');
            $table->text('similar_posts')->nullable()->comment('JSON array of similar post IDs');
            $table->timestamps();
            
            // Index for faster queries
            $table->index('post_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_content_profiles');
    }
}
