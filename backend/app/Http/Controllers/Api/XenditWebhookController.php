<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Xendit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Webhook pembayaran dari Xendit. Dikenali dari header x-callback-token
 * yang harus sama dengan XENDIT_WEBHOOK_TOKEN. Selalu membalas 200 untuk
 * webhook sah (termasuk yang diabaikan) supaya Xendit tidak mengulang.
 */
class XenditWebhookController extends Controller
{
    public function __invoke(Request $request, Xendit $xendit): JsonResponse
    {
        $token = (string) config('services.xendit.webhook_token');
        if ($token === '' || ! hash_equals($token, (string) $request->header('x-callback-token'))) {
            return response()->json(['message' => 'Token webhook tidak sah.', 'kode' => 'token_tidak_sah'], 401);
        }

        $xendit->terimaWebhook($request->json()->all());

        return response()->json(['diterima' => true]);
    }
}
