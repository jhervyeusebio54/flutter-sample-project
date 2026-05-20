import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class CustomerModal extends StatefulWidget {
  final List products;
  const CustomerModal({super.key, required this.products});

  @override
  State<CustomerModal> createState() => _CustomerModalState();
}

class _CustomerModalState extends State<CustomerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List cartItems = [];
  bool isLoadingCart = true;
  bool isCheckingOut = false;
  String sessionKey = '';
  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    sessionKey = _generateSessionKey();
    fetchCart();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generateSessionKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> fetchCart() async {
    setState(() => isLoadingCart = true);
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/cart/$sessionKey'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          cartItems = jsonDecode(response.body);
          isLoadingCart = false;
        });
      } else {
        setState(() => isLoadingCart = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingCart = false);
    }
  }

  Future<void> addToCart(Map product) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_key': sessionKey,
          'product_id': product['id'],
          'name': product['name'],
          'price': product['price'].toString(),
          'quantity': 1,
        }),
      );
      if (!mounted) return;
      await fetchCart();
      _showToast('${product['name']} added to cart');
    } catch (e) {
      debugPrint('ADD TO CART ERROR: $e');
    }
  }

  Future<void> updateCartItem(int productId, int quantity) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_key': sessionKey,
          'product_id': productId,
          'quantity': quantity,
        }),
      );
      if (!mounted) return;
      await fetchCart();
    } catch (e) {
      debugPrint('UPDATE CART ERROR: $e');
    }
  }

  Future<void> checkout() async {
    if (cartItems.isEmpty) return;
    setState(() => isCheckingOut = true);

    final items = cartItems.map((item) => {
      'id': item['product_id'],
      'name': item['name'],
      'quantity': item['quantity'],
      'price': item['price'],
    }).toList();

    final total = cartItems.fold<double>(0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = (item['quantity'] as num).toInt();
      return sum + (price * qty);
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items, 'total': total}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await http.delete(Uri.parse('$baseUrl/cart/$sessionKey'));
        if (!mounted) return;
        await fetchCart();
        _showReceiptDialog(data['orderId'], items, total);
      } else {
        _showToast('Checkout failed');
      }
    } catch (e) {
      if (mounted) _showToast('Could not connect to server');
    } finally {
      if (mounted) setState(() => isCheckingOut = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF2A2A3E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showReceiptDialog(int orderId, List items, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF1D9E75), size: 30),
            ),
            const SizedBox(height: 12),
            const Text('Order Placed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            Text('Order #$orderId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF9090A8), fontSize: 13)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: Color(0xFF2A2A3E)),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} x${item['quantity']}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Text(
                        '₱${(double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] as num).toInt()}',
                        style: const TextStyle(
                            color: Color(0xFF9090A8), fontSize: 13),
                      ),
                    ],
                  ),
                )),
            const Divider(color: Color(0xFF2A2A3E)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text('₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  double get cartTotal => cartItems.fold(0, (sum, item) {
        final price = double.tryParse(item['price'].toString()) ?? 0;
        final qty = (item['quantity'] as num).toInt();
        return sum + (price * qty);
      });

  int get cartCount => cartItems.fold(
      0, (sum, item) => sum + (item['quantity'] as num).toInt());

  String getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '$baseUrl/images/1.jpg';
    return '$baseUrl/images/$image';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13131F),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: Color(0xFF6C63FF), size: 22),
                  const SizedBox(width: 8),
                  const Text('Shop',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF9090A8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF9090A8),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    const Tab(text: 'Products'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Cart'),
                          if (cartCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  widget.products.isEmpty
                      ? const Center(
                          child: Text('No products available',
                              style: TextStyle(color: Color(0xFF9090A8))))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: widget.products.length,
                          itemBuilder: (context, index) {
                            final p = widget.products[index];
                            final inCart = cartItems.any((c) =>
                                c['product_id'].toString() ==
                                p['id'].toString());
                            final cartItem = inCart
                                ? cartItems.firstWhere((c) =>
                                    c['product_id'].toString() ==
                                    p['id'].toString())
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(14),
                                border: inCart
                                    ? Border.all(
                                        color: const Color(0xFF6C63FF),
                                        width: 1)
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    getImageUrl(p['image_url']),
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(0xFF2A2A3E),
                                      child: const Icon(Icons.image_outlined,
                                          color: Color(0xFF9090A8)),
                                    ),
                                  ),
                                ),
                                title: Text(p['name'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('₱${p['price']}',
                                      style: const TextStyle(
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                                trailing: inCart
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _qtyButton(
                                            icon: Icons.remove_rounded,
                                            onTap: () => updateCartItem(
                                              p['id'],
                                              (cartItem!['quantity'] as num)
                                                      .toInt() -
                                                  1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              '${cartItem!['quantity']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                          ),
                                          _qtyButton(
                                            icon: Icons.add_rounded,
                                            onTap: () => updateCartItem(
                                              p['id'],
                                              (cartItem['quantity'] as num)
                                                      .toInt() +
                                                  1,
                                            ),
                                          ),
                                        ],
                                      )
                                    : GestureDetector(
                                        onTap: () => addToCart(p),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('Add',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                  isLoadingCart
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF)))
                      : cartItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      color: const Color(0xFF9090A8),
                                      size: 48),
                                  const SizedBox(height: 12),
                                  const Text('Your cart is empty',
                                      style: TextStyle(
                                          color: Color(0xFF9090A8),
                                          fontSize: 15)),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 8),
                                    itemCount: cartItems.length,
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      final price = double.tryParse(
                                              item['price'].toString()) ??
                                          0;
                                      final qty =
                                          (item['quantity'] as num).toInt();

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E2E),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] ?? '',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '₱${price.toStringAsFixed(2)} each',
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF9090A8),
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _qtyButton(
                                                  icon: Icons.remove_rounded,
                                                  onTap: () => updateCartItem(
                                                      item['product_id'],
                                                      qty - 1),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10),
                                                  child: Text('$qty',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14)),
                                                ),
                                                _qtyButton(
                                                  icon: Icons.add_rounded,
                                                  onTap: () => updateCartItem(
                                                      item['product_id'],
                                                      qty + 1),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '₱${(price * qty).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      color: Color(0xFF6C63FF),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E1E2E),
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(20)),
                                  ),
                                  child: SafeArea(
                                    top: false,
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Total',
                                                style: TextStyle(
                                                    color: Color(0xFF9090A8),
                                                    fontSize: 12)),
                                            Text(
                                              '₱${cartTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: isCheckingOut
                                                  ? null
                                                  : checkout,
                                              child: isCheckingOut
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white))
                                                  : const Text('Checkout',
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 16),
      ),
    );
  }
}