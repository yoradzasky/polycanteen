<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdminController extends Controller
{
    /**
     * Update the admin's password.
     */
    public function updatePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', Password::min(8)->letters()->numbers()->mixedCase()->symbols(), 'confirmed'],
        ], [
            'current_password.required' => 'Password saat ini wajib diisi.',
            'current_password.current_password' => 'Password saat ini tidak cocok dengan data kami.',
            'password.required' => 'Password baru wajib diisi.',
            'password.confirmed' => 'Konfirmasi password baru tidak cocok.',
            'password.min' => 'Password baru harus minimal 8 karakter.',
            'password.letters' => 'Password baru harus mengandung setidaknya satu huruf.',
            'password.numbers' => 'Password baru harus mengandung setidaknya satu angka.',
            'password.mixed' => 'Password baru harus mengandung huruf besar dan huruf kecil.',
            'password.symbols' => 'Password baru harus mengandung setidaknya satu simbol.',
        ]);

        $request->user()->update([
            'password' => Hash::make($validated['password']),
        ]);

        return back()->with('status', 'password-updated');
    }
}
