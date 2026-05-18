import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_product_page.dart';
import 'edit_product_page.dart';

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
          _applyFilter();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _onSearch(String value) {
    setState(() {
      searchQuery = value;
      _applyFilter();
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

  String getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '$baseUrl/images/1.jpg';
    return '$baseUrl/images/$image';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
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
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddProductPage()));
          fetchProducts();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                                  color: Color(0xFF9090A8), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                              contentPadding: const EdgeInsets.symmetric(
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
                                    child: const Icon(Icons.image_outlined,
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
                                        color: Color(0xFF9090A8), size: 20),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                EditProductPage(product: p)),
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