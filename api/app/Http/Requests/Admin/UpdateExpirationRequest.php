<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateExpirationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize()
    {
        // Karena kita sudah menggunakan middleware ['auth', 'role:admin'] di routes/web.php,
        // kita bisa me-return true di sini.
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules()
    {
        return [
            // Meskipun di database namannya 'masa_aktif', dari React (Inertia) 
            // kita mengirimkannya dengan nama state 'active_until'
            'active_until' => 'required|date|after_or_equal:today',
        ];
    }

    /**
     * Get the error messages for the defined validation rules.
     */
    public function messages()
    {
        return [
            'active_until.required' => 'Tanggal masa aktif harus diisi.',
            'active_until.date' => 'Format tanggal tidak valid.',
            'active_until.after_or_equal' => 'Tanggal masa aktif tidak boleh di masa lalu.',
        ];
    }
}