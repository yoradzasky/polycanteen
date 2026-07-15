<?php

namespace App\Services;

use App\Models\User;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Illuminate\Support\Facades\Log;
use Throwable;

class FcmNotificationService
{
    private $messaging;

    public function __construct()
    {
        $firebase = (new Factory)
            ->withServiceAccount(base_path(env('FIREBASE_CREDENTIALS')));
        $this->messaging = $firebase->createMessaging();
    }

    public function sendToUser(User $user, string $title, string $body, array $data = []): bool
    {
        if (!$user->fcm_token) {
            return false;
        }

        return $this->sendToToken($user->fcm_token, $title, $body, $data);
    }

    public function sendToToken(string $token, string $title, string $body, array $data = []): bool
    {
        try {
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification(Notification::create($title, $body))
                ->withData($data);

            $this->messaging->send($message);
            return true;
        } catch (Throwable $e) {
            Log::error('FCM Notification Error: ' . $e->getMessage());
            return false;
        }
    }

    public function sendToBuyerApplication(\App\Models\BuyerApplication $app, string $title, string $body, array $data = []): bool
    {
        if (!$app->fcm_token) {
            return false;
        }
        return $this->sendToToken($app->fcm_token, $title, $body, $data);
    }

    public function sendToKantinOwners(int $kantinId, string $title, string $body, array $data = []): bool
    {
        $kantin = \App\Models\Kantin::with(['pemilik.user', 'pegawai.user'])->find($kantinId);
        if (!$kantin) {
            return false;
        }

        $sentCount = 0;

        if ($kantin->pemilik && $kantin->pemilik->user) {
            if ($this->sendToUser($kantin->pemilik->user, $title, $body, $data)) {
                $sentCount++;
            }
        }

        foreach ($kantin->pegawai as $pegawai) {
            if ($pegawai->user) {
                if ($this->sendToUser($pegawai->user, $title, $body, $data)) {
                    $sentCount++;
                }
            }
        }

        return $sentCount > 0;
    }
}
