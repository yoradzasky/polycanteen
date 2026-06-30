<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class CheckStatusAkun
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (Auth::check() && Auth::user()->status_akun !== 'aktif') {
            if ($request->expectsJson() || $request->is('api/*')) {
                $user = Auth::user();
                if (method_exists($user, 'currentAccessToken') && $user->currentAccessToken()) {
                    $user->currentAccessToken()->delete();
                }
                
                return response()->json([
                    'success' => false,
                    'message' => 'Akun Anda belum aktif atau sedang dinonaktifkan. Silakan hubungi admin.'
                ], 403);
            }
            
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
            
            return redirect()->route('login')->withErrors([
                'email' => 'Akun Anda belum aktif atau sedang dinonaktifkan. Silakan hubungi admin.',
            ]);
        }

        return $next($request);
    }
}
