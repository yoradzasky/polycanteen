<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreCanteenRequest;
use App\Services\CanteenService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class CanteenController extends Controller
{
    /**
     * Inject CanteenService via constructor.
     */
    public function __construct(private readonly CanteenService $canteenService) {}

    /**
     * Menampilkan halaman daftar semua kantin (tabel utama dashboard).
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Inertia\Response
     */
    public function index(Request $request): Response
    {
        $filters = $request->only(['nama_kantin', 'status_toko']);

        $canteens = $this->canteenService
            ->getPaginatedCanteens($filters)
            ->withQueryString();

        return Inertia::render('Canteen/Index', [
            'canteens' => $canteens,
            'filters'  => $filters,
        ]);
    }

    /**
     * Menampilkan halaman detail + analitik satu kantin.
     *
     * @param  int  $id
     * @return \Inertia\Response
     */
    public function show(int $id): Response
    {
        $profileAndStats = $this->canteenService->getCanteenProfileAndStats($id);
        $menus           = $this->canteenService->getPaginatedMenus($id);
        $salesActivity   = $this->canteenService->getDailySalesActivity($id);

        return Inertia::render('Canteen/Show', [
            'kantin'            => $profileAndStats['kantin'],
            'total_penjualan'   => $profileAndStats['total_penjualan'],
            'total_menu_terjual'=> $profileAndStats['total_menu_terjual'],
            'menus'             => $menus,
            'sales_activity'    => $salesActivity,
        ]);
    }

    /**
     * Menampilkan halaman form Tambah Kantin (kosong).
     *
     * @return \Inertia\Response
     */
    public function create(): Response
    {
        return Inertia::render('Canteen/Create');
    }

    /**
     * Memproses form Tambah Kantin dan menyimpan data baru.
     *
     * @param  \App\Http\Requests\Admin\StoreCanteenRequest  $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function store(StoreCanteenRequest $request): RedirectResponse
    {
        try {
            $this->canteenService->createCanteen($request->validated());

            return redirect()
                ->route('admin.canteens.index')
                ->with('success', 'Kantin berhasil ditambahkan.');
        } catch (\Exception $e) {
            return redirect()
                ->back()
                ->with('error', 'Gagal menambahkan kantin.');
        }
    }

    /**
     * Menampilkan halaman form Edit Kantin (pre-filled dengan data existing).
     *
     * @param  int  $id
     * @return \Inertia\Response
     */
    public function edit(int $id): Response
    {
        $data = $this->canteenService->getCanteenProfileAndStats($id);

        return Inertia::render('Canteen/Edit', [
            'kantin' => $data['kantin'],
        ]);
    }

    /**
     * Memproses form Edit dan memperbarui data kantin.
     *
     * @param  \App\Http\Requests\Admin\StoreCanteenRequest  $request
     * @param  int  $id
     * @return \Illuminate\Http\RedirectResponse
     */
    public function update(StoreCanteenRequest $request, int $id): RedirectResponse
    {
        try {
            $this->canteenService->updateCanteen($id, $request->validated());

            return redirect()
                ->route('admin.canteens.show', $id)
                ->with('success', 'Kantin berhasil diperbarui.');
        } catch (\Exception $e) {
            return redirect()
                ->back()
                ->with('error', 'Gagal memperbarui kantin.');
        }
    }

    /**
     * Menonaktifkan (soft delete + suspend) kantin.
     *
     * @param  int  $id
     * @return \Illuminate\Http\RedirectResponse
     */
    public function destroy(int $id): RedirectResponse
    {
        try {
            $this->canteenService->deleteCanteen($id);

            return redirect()
                ->route('admin.canteens.index')
                ->with('success', 'Kantin berhasil dinonaktifkan.');
        } catch (\Exception $e) {
            return redirect()
                ->back()
                ->with('error', 'Gagal menonaktifkan kantin.');
        }
    }
}
