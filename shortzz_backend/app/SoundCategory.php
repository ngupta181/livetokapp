<?php

namespace App;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;

class SoundCategory extends Authenticatable
{
	use HasApiTokens;
	protected $table = 'tbl_sound_category';
	public $primaryKey = 'sound_category_id';
	public $timestamps = true;
	public $incrementing = false;
	
    /**
	 * The attributes that are mass assignable.
	 *
	 * @var array
	 */
	protected $fillable = [
		'sound_category_name',
		'is_deleted',
		'sound_category_image',
		'sound_category_profile'
	];
}
