import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'add_product_page.dart';
import 'edit_product_page.dart';


class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}


class _ProductListPageState extends State<ProductListPage> {
  List products = [];
  bool isLoading = true;


  final String baseUrl = 'http://localhost:3000';


  @override
  void initState() {
    super.initState();
    fetchProducts();
  }


  // =======================
  // FETCH PRODUCTS
  // =======================
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
      );


      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("FETCH ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  // =======================
  // DELETE PRODUCT
  // =======================
  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
      );


      if (response.statusCode == 200) {
        fetchProducts(); // refresh list
      }
    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }


  // =======================
  // IMAGE URL
  // =======================
  String getImageUrl(String? image) {
    if (image == null || image.isEmpty) {
      return '$baseUrl/images/1.jpg';
    }
    return '$baseUrl/images/$image';
  }


  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Products")),


      // ➕ ADD PRODUCT BUTTON
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage()),
          );


          fetchProducts(); // refresh after add
        },
      ),


      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(child: Text("No products found"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];


                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: ListTile(
                        // 🖼 IMAGE
                        leading: Image.network(
                          getImageUrl(p['image_url']),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image),
                        ),


                        // 📦 NAME
                        title: Text(p['name'] ?? ''),


                        // 💰 PRICE
                        subtitle: Text("₱${p['price']}"),


                        // ✏️ EDIT + 🗑 DELETE
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProductPage(product: p),
                                  ),
                                );


                                // refresh after edit
                                if (result == true) {
                                  fetchProducts();
                                }
                              },
                            ),


                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteProduct(p['id'].toString());
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
