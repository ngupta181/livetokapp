<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateContactsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tbl_contacts', function (Blueprint $table) {
            $table->bigIncrements('contact_id');
            $table->unsignedBigInteger('user_id');
            $table->string('csv_file_path')->comment('Path to the stored CSV file');
            $table->timestamps();
            
            // Add index for faster queries
            $table->index('user_id');
            
            // Note: Foreign key constraint removed to avoid migration issues
            // If you need the constraint, verify that tbl_users.user_id exists and has matching type
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tbl_contacts');
    }
}
