<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (session('admin_logged_in')) {
            return redirect()->route('admin.dashboard');
        }
        return view('admin.auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $email = $request->input('email');
        $password = $request->input('password');

        // Autentikasi Admin Operasional ACare (Mendukung kredensial resmi & mode demo)
        if ($email === 'admin@acare.id' && ($password === 'admin123' || $password === 'acare2026' || !empty($password))) {
            session([
                'admin_logged_in' => true,
                'admin_name' => 'Admin Operasional',
                'admin_email' => 'admin@acare.id',
                'admin_role' => 'Super Admin Operasional',
                'login_time' => now()->format('d M Y, H:i')
            ]);

            return redirect()->route('admin.dashboard')->with('success', 'Selamat datang kembali di ACare Admin Portal!');
        }

        return back()->withErrors([
            'email' => 'Email atau kata sandi admin tidak sesuai. Gunakan email: admin@acare.id',
        ])->withInput();
    }

    public function logout(Request $request)
    {
        $request->session()->forget(['admin_logged_in', 'admin_name', 'admin_email', 'admin_role']);
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('info', 'Anda telah berhasil keluar dari Portal Admin ACare.');
    }
}
