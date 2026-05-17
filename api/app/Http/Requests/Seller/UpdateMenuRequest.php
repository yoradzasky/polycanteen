<?php

namespace App\Http\Requests\Seller;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMenuRequest extends FormRequest
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
            'nama_item' => 'nullable|string|max:255',
            'harga' => 'nullable|integer|min:0',
            'kategori' => 'nullable|string|max:255',
            'pilihan_layanan' => 'nullable|array',
            'pilihan_layanan.*' => 'string|in:makan_di_tempat,dibungkus,pengantaran',
            'deskripsi' => 'nullable|string',
            'estimasi_waktu' => 'nullable|integer|min:1',
            'foto_menu' => 'nullable|image|max:2048',
            'varian' => 'nullable|json',
            'topping' => 'nullable|json',
        ];
    }
}
