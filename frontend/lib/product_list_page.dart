import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_product_page.dart';
import 'edit_product_page.dart';
import 'customer_modal.dart';

enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc, newest, oldest }

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List products = [];
  List filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';
  SortOption currentSort = SortOption.newest;
  final TextEditingController searchController = TextEditingController();

  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          _applyFilterAndSort();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilterAndSort() {
    List result = searchQuery.isEmpty
        ? List.from(products)
        : products.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

    switch (currentSort) {
      case SortOption.nameAsc:
        result.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
        break;
      case SortOption.nameDesc:
        result.sort((a, b) => (b['name'] ?? '')
            .toString()
            .compareTo((a['name'] ?? '').toString()));
        break;
      case SortOption.priceAsc:
        result.sort((a, b) {
          final pa = double.tryParse(a['price'].toString()) ?? 0;
          final pb = double.tryParse(b['price'].toString()) ?? 0;
          return pa.compareTo(pb);
        });
        break;
      case SortOption.priceDesc:
        result.sort((a, b) {
          final pa = double.tryParse(a['price'].toString()) ?? 0;
          final pb = double.tryParse(b['price'].toString()) ?? 0;
          return pb.compareTo(pa);
        });
        break;
      case SortOption.newest:
        result.sort((a, b) => (b['id'] ?? 0)
            .toString()
            .compareTo((a['id'] ?? 0).toString()));
        break;
      case SortOption.oldest:
        result.sort((a, b) => (a['id'] ?? 0)
            .toString()
            .compareTo((b['id'] ?? 0).toString()));
        break;
    }

    filteredProducts = result;
  }

  void _onSearch(String value) {
    setState(() {
      searchQuery = value;
      _applyFilterAndSort();
    });
  }

  void _onSortChanged(SortOption option) {
    setState(() {
      currentSort = option;
      _applyFilterAndSort();
    });
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/products/$id'));
      if (!mounted) return;
      if (response.statusCode == 200) fetchProducts();
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
    }
  }

  void _confirmDelete(BuildContext context, Map product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete product?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
          'Remove "${product['name']}" from your inventory? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF9090A8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9090A8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(product['id'].toString());
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: const Text('You will be returned to the login screen.',
            style: TextStyle(color: Color(0xFF9090A8), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9090A8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final options = [
        (SortOption.newest, Icons.schedule_rounded, 'Newest first'),
        (SortOption.oldest, Icons.history_rounded, 'Oldest first'),
        (SortOption.nameAsc, Icons.sort_by_alpha_rounded, 'Name A → Z'),
        (SortOption.nameDesc, Icons.sort_by_alpha_rounded, 'Name Z → A'),
        (SortOption.priceAsc, Icons.arrow_upward_rounded, 'Price low → high'),
        (SortOption.priceDesc, Icons.arrow_downward_rounded, 'Price high → low'),
      ];

      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9090A8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Sort by',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...options.map((o) {
                final isSelected = currentSort == o.$1;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(o.$2,
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF9090A8),
                      size: 20),
                  title: Text(o.$3,
                      style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF6C63FF), size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _onSortChanged(o.$1);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
  String _sortLabel() {
    switch (currentSort) {
      case SortOption.nameAsc:
        return 'A→Z';
      case SortOption.nameDesc:
        return 'Z→A';
      case SortOption.priceAsc:
        return 'Price ↑';
      case SortOption.priceDesc:
        return 'Price ↓';
      case SortOption.newest:
        return 'Newest';
      case SortOption.oldest:
        return 'Oldest';
    }
  }

  String getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '$baseUrl/images/1.jpg';
    return '$baseUrl/images/$image';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
      IconButton(
        icon: const Icon(Icons.storefront_outlined, color: Color(0xFF6C63FF)),
        tooltip: 'Customer view',
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CustomerModal(products: products),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFF9090A8)),
        tooltip: 'Log out',
        onPressed: () => _confirmLogout(context),
      ),
      const SizedBox(width: 4),
    ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddProductPage()));
          fetchProducts();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _onSearch,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF9090A8), size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF9090A8), size: 18),
                              onPressed: () {
                                searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentSort != SortOption.newest
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          color: currentSort != SortOption.newest
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF9090A8),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sortLabel(),
                          style: TextStyle(
                            color: currentSort != SortOption.newest
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF9090A8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (!isLoading && searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredProducts.length} result${filteredProducts.length != 1 ? 's' : ''} for "$searchQuery"',
                  style: const TextStyle(
                      color: Color(0xFF9090A8), fontSize: 12),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF)))
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF9090A8), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No products match your search'
                                  : 'No products yet',
                              style: const TextStyle(
                                  color: Color(0xFF9090A8),
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // accounts for FAB + system nav bar height
                        padding: EdgeInsets.fromLTRB(
                            16, 4, 16, 80 + bottomPadding),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = filteredProducts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  getImageUrl(p['image_url']),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: const Color(0xFF2A2A3E),
                                    child: const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF9090A8)),
                                  ),
                                ),
                              ),
                              title: Text(
                                p['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '₱${p['price']}',
                                  style: const TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF9090A8),
                                        size: 20),
                                    onPressed: () async {
                                      final result =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                EditProductPage(
                                                    product: p)),
                                      );
                                      if (result == true) fetchProducts();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red.shade400,
                                        size: 20),
                                    onPressed: () =>
                                        _confirmDelete(context, p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}