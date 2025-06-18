<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $table = 'tbl_transactions';
    protected $primaryKey = 'transaction_id';
    public $timestamps = true;
    
    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'user_id', 
        'to_user_id', 
        'transaction_type', 
        'coins', 
        'amount', 
        'payment_method',
        'transaction_reference',
        'platform',
        'gift_id',
        'status',
        'meta_data'
    ];
    
    /**
     * Get the user that owns the transaction.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
    
    /**
     * Get the recipient user if applicable.
     */
    public function recipient()
    {
        return $this->belongsTo(User::class, 'to_user_id', 'user_id');
    }
    
    /**
     * Get the gift related to this transaction.
     */
    public function gift()
    {
        return $this->belongsTo(Gifts::class, 'gift_id', 'id');
    }
} 