<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class UpdateCommentsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('tbl_comments', function (Blueprint $table) {
            // Add parent_id for nested replies
            $table->integer('parent_id')->nullable()->after('post_id');
            
            // Add is_edited flag to track if a comment has been edited
            $table->boolean('is_edited')->default(false)->after('comment');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('tbl_comments', function (Blueprint $table) {
            $table->dropColumn('parent_id');
            $table->dropColumn('is_edited');
        });
    }
}
