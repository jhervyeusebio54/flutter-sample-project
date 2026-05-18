import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key, required this.product});
  final Map product;

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  Uint8List? newImage;
  final picker = ImagePicker();
  bool isLoading = false;

  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.product['name']);
    priceController =
        TextEditingController(text: widget.product['price'].toString());
  }

  String getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '$baseUrl/images/1.jpg';
    return '$baseUrl/images/$image';
  }

  Future<void> pickImage() async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => newImage = bytes);
    }
  }

  Future<void> updateProduct() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    final id = widget.product['id'];

    try {
      http.Response? response;

      if (newImage != null) {
        final uri = Uri.parse('$baseUrl/products/$id');
        final request = http.MultipartRequest('PUT', uri);
        request.fields['name'] = nameController.text.trim();
        request.fields['price'] = priceController.text.trim();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          newImage!,
          filename: 'product.jpg',
        ));
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.put(
          Uri.parse('$baseUrl/products/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': nameController.text.trim(),
            'price': priceController.text.trim(),
          }),
        );
      }

      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Update failed'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not connect to server'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: newImage != null
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF2A2A3E),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: newImage != null
                          ? Image.memory(newImage!,
                              fit: BoxFit.cover, width: double.infinity)
                          : Image.network(
                              getImageUrl(widget.product['image_url']),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_outlined,
                                    color: Color(0xFF9090A8), size: 40),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF9090A8), size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money_rounded,
                    color: Color(0xFF9090A8), size: 20),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProduct,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}