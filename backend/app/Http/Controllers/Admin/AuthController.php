<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pengguna;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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
        $credentials = $request->validate([
            'email' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'email.required' => 'Email atau nomor telepon wajib diisi.',
            'password.required' => 'Kata sandi wajib diisi.',
        ]);

        $loginInput = trim($credentials['email']);

        // Cari pengguna berdasarkan email atau nomor telepon
        $pengguna = Pengguna::query()
            ->where('email', $loginInput)
            ->first();

        if (!$pengguna || !Hash::check($credentials['password'], $pengguna->kata_sandi)) {
            return back()->withErrors([
                'email' => 'Email atau kata sandi salah.',
            ])->withInput($request->only('email'));
        }

        // Pastikan akun memiliki peran admin
        if ($pengguna->role !== Pengguna::ROLE_ADMIN) {
            return back()->withErrors([
                'email' => 'Akun ini tidak memiliki akses ke Portal Admin.',
            ])->withInput($request->only('email'));
        }

        // Pastikan status akun aktif
        if (!$pengguna->isAktif()) {
            return back()->withErrors([
                'email' => 'Akun admin tidak aktif. Hubungi administrator sistem.',
            ])->withInput($request->only('email'));
        }

        $request->session()->regenerate();

        session([
            'admin_logged_in' => true,
            'admin_id' => $pengguna->id_pengguna,
            'admin_name' => $pengguna->nama,
            'admin_email' => $pengguna->email,
            'admin_role' => $pengguna->role,
            'login_time' => now()->format('d M Y, H:i'),
        ]);

        return redirect()
            ->route('admin.dashboard')
            ->with('success', 'Selamat datang kembali di ACare Admin Portal!');
    }

    public function logout(Request $request)
    {
        $request->session()->forget([
            'admin_logged_in',
            'admin_id',
            'admin_name',
            'admin_email',
            'admin_role',
            'login_time',
        ]);

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()
            ->route('admin.login')
            ->with('info', 'Anda telah berhasil keluar dari Portal Admin ACare.');
    }
}
