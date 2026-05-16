import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductPage extends StatefulWidget {
  final Map product;

  EditProductPage({required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;

  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.product['name']);

    priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
  }

  // =======================
  // UPDATE PRODUCT (FIXED)
  // =======================
  Future<void> updateProduct() async {
    final id = widget.product['id'];

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'price': priceController.text.trim(),
        }),
      );

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE BODY: ${response.body}");

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // return success
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed")));
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot connect to server")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Product")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Product Name"),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Price"),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: updateProduct, child: Text("Update")),
          ],
        ),
      ),
    );
  }
}