<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddLocationFieldsToUsersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            $table->string('user_country', 100)->nullable()->after('user_profile');
            $table->string('user_state', 100)->nullable()->after('user_country');
            $table->string('user_city', 100)->nullable()->after('user_state');
            $table->string('user_ip', 45)->nullable()->after('user_city');
            
            // Add indexes for better query performance
            $table->index('user_country');
            $table->index('user_state');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            $table->dropIndex(['user_country']);
            $table->dropIndex(['user_state']);
            $table->dropColumn(['user_country', 'user_state', 'user_city', 'user_ip']);
        });
    }
} 