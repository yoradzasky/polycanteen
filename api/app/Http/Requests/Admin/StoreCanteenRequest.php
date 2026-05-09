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

        return [
            // ── Data Kantin ──────────────────────────────────────────

            'nama_kantin'   => ['required', 'string', 'max:100'],
            'lokasi_gedung' => ['required', 'string', 'max:255'],
            'latitude'      => ['required', 'numeric', 'between:-90,90'],
            'longitude'     => ['required', 'numeric', 'between:-180,180'],

            // ── Data Pemilik ─────────────────────────────────────────
            'nama_pemilik' => ['required', 'string', 'max:100'],
            'no_hp'        => [
                'required',
                'string',
                'max:15',
                'regex:/^(\+62|62|0)8[1-9][0-9]{6,10}$/',
            ],
            'email_pemilik' => [
                'required',
                'email',
                'max:255',
                // Ignore berdasarkan kantin_id dari route — developer perlu menyesuaikan
                // jika relasi ke user_id lebih kompleks (misal: resolve user_id dari pemilik).
                Rule::unique('users', 'email')->ignore($kantinId, 'kantin_id'),
            ],
            'password_pemilik' => [
                Rule::requiredIf($this->isMethod('post')),
                'nullable',
                'string',
                'min:8',
                'confirmed',
            ],

            // ── Data Karyawan (opsional) ─────────────────────────────
            'karyawan'                    => ['nullable', 'array'],
            'karyawan.*.nama_karyawan'    => ['required_with:karyawan.*', 'string', 'max:100'],
            'karyawan.*.email_karyawan'   => [
                'required_with:karyawan.*',
                'email',
                'max:255',
                'distinct',
                Rule::unique('users', 'email'),
            ],
            'karyawan.*.no_hp_karyawan'   => ['nullable', 'string', 'max:15'],
            'karyawan.*.password_karyawan' => [
                Rule::requiredIf($this->isMethod('post')),
                'nullable',
                'string',
                'min:8',
            ],
        ];
    }

    /**
     * Pesan error kustom dalam Bahasa Indonesia.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [

            'nama_kantin.required'              => 'Nama kantin wajib diisi.',
            'lokasi_gedung.required'            => 'Lokasi gedung wajib diisi.',
            'latitude.between'                  => 'Latitude harus antara -90 dan 90.',
            'longitude.between'                 => 'Longitude harus antara -180 dan 180.',
            'nama_pemilik.required'             => 'Nama pemilik wajib diisi.',
            'no_hp.required'                    => 'Nomor HP wajib diisi.',
            'no_hp.regex'                       => 'Format nomor HP tidak valid (contoh: 08123456789).',
            'email_pemilik.required'            => 'Email pemilik wajib diisi.',
            'email_pemilik.unique'              => 'Email ini sudah terdaftar.',
            'password_pemilik.required_if'      => 'Password wajib diisi saat menambah kantin baru.',
            'password_pemilik.min'              => 'Password minimal 8 karakter.',
            'karyawan.*.email_karyawan.distinct' => 'Email karyawan tidak boleh duplikat.',
            'karyawan.*.email_karyawan.unique'  => 'Email karyawan sudah terdaftar.',
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

            'nama_kantin'                => 'nama kantin',
            'lokasi_gedung'              => 'lokasi gedung',
            'nama_pemilik'               => 'nama pemilik',
            'no_hp'                      => 'nomor HP',
            'email_pemilik'              => 'email pemilik',
            'password_pemilik'           => 'password pemilik',
            'karyawan.*.nama_karyawan'   => 'nama karyawan',
            'karyawan.*.email_karyawan'  => 'email karyawan',
        ];
    }
}
