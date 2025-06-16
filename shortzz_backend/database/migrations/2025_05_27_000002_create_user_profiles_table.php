<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUserProfilesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_user_profiles', function (Blueprint $table) {
            $table->bigIncrements('profile_id');
            $table->integer('user_id')->unique();
            $table->text('interests')->nullable()->comment('JSON array of user interests');
            $table->text('favorite_hashtags')->nullable()->comment('JSON array of user favorite hashtags');
            $table->text('favorite_sounds')->nullable()->comment('JSON array of user favorite sounds');
            $table->text('watched_categories')->nullable()->comment('JSON array of categories with watch counts');
            $table->integer('avg_watch_duration')->default(0);
            $table->timestamps();
            
            // Index for faster queries
            $table->index('user_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_user_profiles');
    }
}
