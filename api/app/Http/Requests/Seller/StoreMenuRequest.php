<?php

namespace App\Http\Requests\Seller;

use Illuminate\Foundation\Http\FormRequest;

class StoreMenuRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization is handled via Policy and Controller
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'nama_item' => 'required|string|max:255',
            'harga' => 'required|integer|min:0',
            'kategori' => 'required|string|max:255',
            'pilihan_layanan' => 'required|array',
            'pilihan_layanan.*' => 'string|in:makan_di_tempat,dibungkus,pengantaran',
            'deskripsi' => 'nullable|string',
            'estimasi_waktu' => 'nullable|integer|min:1',
            'foto_menu' => 'nullable|image|max:10240',
            'varian' => 'nullable|json',
        ];
    }
}
