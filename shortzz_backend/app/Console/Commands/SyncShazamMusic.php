<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\Admin\SoundController;
use Illuminate\Http\Request;

class SyncShazamMusic extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'shazam:sync';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Sync trending music tracks from Shazam API';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        $this->info('Starting Shazam music sync...');
        
        $controller = new SoundController();
        $request = new Request();
        
        $response = $controller->fetchShazamTrending($request);
        $data = json_decode($response->getContent(), true);
        
        if (isset($data['success']) && $data['success'] == 1) {
            $this->info('Sync completed successfully!');
            $this->info("Added: {$data['data']['added']} tracks");
            $this->info("Updated: {$data['data']['updated']} tracks");
            $this->info("Skipped: {$data['data']['skipped']} tracks");
            return 0;
        } else {
            $this->error('Sync failed: ' . ($data['message'] ?? 'Unknown error'));
            return 1;
        }
    }
}
