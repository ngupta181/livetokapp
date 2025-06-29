<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddUserLevelFields extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('tbl_user', function (Blueprint $table) {
            // Add level system fields
            $table->integer('user_level')->default(1)->after('profile_category');
            $table->integer('user_level_points')->default(0)->after('user_level');
            $table->string('user_level_badge')->nullable()->after('user_level_points');
            $table->string('user_avatar_frame')->nullable()->after('user_level_badge');
            $table->boolean('has_entry_effect')->default(false)->after('user_avatar_frame');
            $table->string('entry_effect_url')->nullable()->after('has_entry_effect');
            $table->timestamp('last_level_activity_date')->nullable()->after('entry_effect_url');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('tbl_user', function (Blueprint $table) {
            $table->dropColumn([
                'user_level',
                'user_level_points',
                'user_level_badge',
                'user_avatar_frame',
                'has_entry_effect',
                'entry_effect_url',
                'last_level_activity_date'
            ]);
        });
    }
} 