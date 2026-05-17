<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCanteenRequest extends FormRequest
{
    /**
     * Otorisasi request — ditangani oleh middleware di level route.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Aturan validasi untuk form Tambah/Edit Kantin.
     *
     * Menggunakan $this->isMethod('post') untuk membedakan aturan store vs update,
     * dan $this->route('id') untuk mengecualikan record saat ini dari validasi unique.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $kantinId = $this->route('id');
        $userIdPemilik = null;

        // Ambil user_id pemilik jika sedang proses update
        if ($kantinId) {
            $pemilik = \App\Models\Pemilik::where('kantin_id', $kantinId)->first();
            if ($pemilik) {
                $userIdPemilik = $pemilik->user_id;
            }
        }

        // Kumpulkan user_id milik karyawan existing agar bisa di-exclude dari unique check
        $karyawanUserIds = [];
        if ($kantinId && $this->has('karyawan')) {
            foreach ($this->input('karyawan', []) as $index => $karyawanData) {
                if (!empty($karyawanData['id'])) {
                    $pegawai = \App\Models\Pegawai::find($karyawanData['id']);
                    if ($pegawai) {
                        $karyawanUserIds[$index] = $pegawai->user_id;
                    }
                }
            }
        }

        // Build aturan email per karyawan secara dinamis
        $karyawanEmailRules = [];
        foreach ($this->input('karyawan', []) as $index => $karyawanData) {
            $emailRule = [
                'required_with:karyawan.*',
                'email',
                'max:255',
                'distinct',
                'different:email',
            ];

            // Jika karyawan existing (punya id), exclude user_id-nya dari unique
            if (isset($karyawanUserIds[$index])) {
                $emailRule[] = Rule::unique('users', 'email')->ignore($karyawanUserIds[$index]);
            } else {
                $emailRule[] = Rule::unique('users', 'email');
            }

            $karyawanEmailRules["karyawan.{$index}.email"] = $emailRule;
        }

        $rules = [
            // ── Data Kantin ──────────────────────────────────────────

            'nama_kantin' => ['required', 'string', 'max:100'],
            'lokasi_lengkap' => ['required', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],

            // ── Data Pemilik ─────────────────────────────────────────
            'nama_pemilik' => ['required', 'string', 'max:100'],
            'no_telp' => [
                'required',
                'string',
                'max:15',
                'regex:/^(\+62|62|0)8[1-9][0-9]{6,10}$/',
            ],
            'email' => [
                'required',
                'email',
                'max:255',
                // Ignore user_id milik pemilik saat ini jika sedang update
                $userIdPemilik ? Rule::unique('users', 'email')->ignore($userIdPemilik) : Rule::unique('users', 'email'),
            ],

            // ── Data Karyawan (opsional) ─────────────────────────────
            'karyawan' => ['nullable', 'array'],
            'karyawan.*.id' => ['nullable', 'integer'],
            'karyawan.*.nama_karyawan' => ['required_with:karyawan.*', 'string', 'max:100'],
            'karyawan.*.no_telp' => [
                'nullable',
                'string',
                'max:15',
                'regex:/^(\+62|62|0)8[1-9][0-9]{6,10}$/',
            ],
        ];

        // Merge aturan email karyawan yang sudah di-build per-index
        return array_merge($rules, $karyawanEmailRules);
    }

    /**
     * Pesan error kustom dalam Bahasa Indonesia.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [

            'nama_kantin.required' => 'Nama kantin wajib diisi.',
            'lokasi_lengkap.required' => 'Lokasi kantin wajib diisi.',
            'latitude.between' => 'Latitude harus antara -90 dan 90.',
            'longitude.between' => 'Longitude harus antara -180 dan 180.',
            'nama_pemilik.required' => 'Nama pemilik wajib diisi.',
            'no_telp.required' => 'Nomor HP wajib diisi.',
            'no_telp.regex' => 'Format nomor HP tidak valid (contoh: 08123456789).',
            'email.required' => 'Email pemilik wajib diisi.',
            'email.unique' => 'Email ini sudah terdaftar.',
            'karyawan.*.email.distinct' => 'Email karyawan tidak boleh duplikat satu sama lain.',
            'karyawan.*.email.different' => 'Email karyawan tidak boleh sama dengan email pemilik.',
            'karyawan.*.email.unique' => 'Email karyawan sudah terdaftar.',
            'karyawan.*.no_telp.regex' => 'Format nomor HP karyawan tidak valid (contoh: 08123456789).',
        ];
    }

    /**
     * Nama atribut yang lebih ramah untuk pesan error default.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [

            'nama_kantin' => 'nama kantin',
            'lokasi_lengkap' => 'lokasi kantin',
            'nama_pemilik' => 'nama pemilik',
            'no_telp' => 'nomor HP',
            'email' => 'email pemilik',
            'karyawan.*.nama_karyawan' => 'nama karyawan',
            'karyawan.*.email' => 'email karyawan',
            'karyawan.*.no_telp' => 'nomor HP karyawan',
        ];
    }
}
