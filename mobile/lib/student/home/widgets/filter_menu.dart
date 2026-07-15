import 'package:flutter/material.dart';

class FilterMenu extends StatefulWidget {
  final List<String> categories;
  final String? initialCategory;
  final String? initialPriceSort; // 'asc' (terendah), 'desc' (tertinggi)
  final String? initialTimeSort; // 'asc' (tercepat), 'desc' (terlama)
  final Function(String? category, String? priceSort, String? timeSort) onApply;

  const FilterMenu({
    super.key,
    required this.categories,
    this.initialCategory,
    this.initialPriceSort,
    this.initialTimeSort,
    required this.onApply,
  });

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> {
  String? _selectedCategory;
  String? _selectedPriceSort;
  String? _selectedTimeSort;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedPriceSort = widget.initialPriceSort;
    _selectedTimeSort = widget.initialTimeSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter Menu",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3138),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Kategori
          if (widget.categories.isNotEmpty) ...[
            const Text(
              "Kategori",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.categories.map((kategori) {
                final isSelected = _selectedCategory == kategori;
                return ChoiceChip(
                  label: Text(kategori),
                  selected: isSelected,
                  selectedColor: const Color(0xFFF2994A).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFD4823A)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFF2994A)
                          : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? kategori : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Urutkan Harga
          const Text(
            "Urutkan Harga",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSortOption(
                  label: "Terendah",
                  icon: Icons.arrow_downward,
                  isSelected: _selectedPriceSort == 'asc',
                  onTap: () => setState(() {
                    _selectedPriceSort = _selectedPriceSort == 'asc'
                        ? null
                        : 'asc';
                    // PERBAIKAN: Tidak lagi me-reset _selectedTimeSort
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSortOption(
                  label: "Tertinggi",
                  icon: Icons.arrow_upward,
                  isSelected: _selectedPriceSort == 'desc',
                  onTap: () => setState(() {
                    _selectedPriceSort = _selectedPriceSort == 'desc'
                        ? null
                        : 'desc';
                    // PERBAIKAN: Tidak lagi me-reset _selectedTimeSort
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Urutkan Waktu Estimasi
          const Text(
            "Waktu Estimasi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSortOption(
                  label: "Tercepat",
                  icon: Icons.bolt,
                  isSelected: _selectedTimeSort == 'asc',
                  onTap: () => setState(() {
                    _selectedTimeSort = _selectedTimeSort == 'asc'
                        ? null
                        : 'asc';
                    // PERBAIKAN: Tidak lagi me-reset _selectedPriceSort
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSortOption(
                  label: "Terlama",
                  icon: Icons.hourglass_bottom,
                  isSelected: _selectedTimeSort == 'desc',
                  onTap: () => setState(() {
                    _selectedTimeSort = _selectedTimeSort == 'desc'
                        ? null
                        : 'desc';
                    // PERBAIKAN: Tidak lagi me-reset _selectedPriceSort
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Tombol Aksi
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedPriceSort = null;
                      _selectedTimeSort = null;
                    });
                    widget.onApply(null, null, null);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Reset",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2994A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onApply(
                      _selectedCategory,
                      _selectedPriceSort,
                      _selectedTimeSort,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Terapkan Filter",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF2994A).withOpacity(0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? const Color(0xFFF2994A) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFFD4823A)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFD4823A)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
