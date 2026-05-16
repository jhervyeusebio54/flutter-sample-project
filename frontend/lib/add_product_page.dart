import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}


class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();


  Uint8List? selectedImage;
  final picker = ImagePicker();


  // =======================
  // PICK IMAGE (WEB + MOBILE)
  // =======================
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);


    if (picked != null) {
      final bytes = await picked.readAsBytes();


      setState(() {
        selectedImage = bytes;
      });
    }
  }


  // =======================
  // UPLOAD PRODUCT
  // =======================
  Future<void> uploadProduct() async {
    final uri = Uri.parse('http://localhost:3000/products');


    var request = http.MultipartRequest('POST', uri);


    request.fields['name'] = nameController.text;
    request.fields['price'] = priceController.text;


    if (selectedImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          selectedImage!,
          filename: 'product.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }


    try {
      final response = await request.send();


      if (response.statusCode == 200) {
        print("✅ Product uploaded successfully");


        setState(() {
          nameController.clear();
          priceController.clear();
          selectedImage = null;
        });
      } else {
        print("❌ Upload failed");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }


  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Product")),
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
              keyboardType: TextInputType.number,
            ),


            SizedBox(height: 10),


            // IMAGE PREVIEW (WEB + MOBILE)
            selectedImage != null
                ? Image.memory(selectedImage!, height: 120)
                : Text("No image selected"),


            SizedBox(height: 10),


            ElevatedButton(onPressed: pickImage, child: Text("Pick Image")),


            SizedBox(height: 10),


            ElevatedButton(
              onPressed: uploadProduct,
              child: Text("Upload Product"),
            ),
          ],
        ),
      ),
    );
  }
}


