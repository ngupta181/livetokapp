<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function showRemovePage()
    {
        // Your app's deep link URL scheme
        $appLink = 'livetok://delete-account';
        
        // Play Store link for your app
        $playStoreLink = 'https://play.google.com/store/apps/details?id=com.live.tok.app';

        return view('account-remove', [
            'appLink' => $appLink,
            'playStoreLink' => $playStoreLink
        ]);
    }
} 