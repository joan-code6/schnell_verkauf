import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_data.dart';
import '../services/kleinanzeigen_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductData productData;
  
  const EditProductScreen({
    super.key,
    required this.productData,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.productData.title);
    _descriptionController = TextEditingController(text: widget.productData.description);
    _priceController = TextEditingController(text: widget.productData.price.toStringAsFixed(2));
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  ProductData _getUpdatedProductData() {
    return widget.productData.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? widget.productData.price,
    );
  }
  
  Future<void> _postToKleinanzeigen() async {
    final updatedData = _getUpdatedProductData();
    
    // Validate data
    if (updatedData.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Titel eingeben')),
      );
      return;
    }
    
    if (updatedData.description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Beschreibung eingeben')),
      );
      return;
    }
    
    if (updatedData.price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen gültigen Preis eingeben')),
      );
      return;
    }
    
    await KleinanzeigenService.showPostAdWebView(context, updatedData);
  }
  

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: AppBar(
        title: const Text('Produktdaten bearbeiten'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images preview
            const Text(
              'Fotos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.productData.imagePaths.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(widget.productData.imagePaths[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Title field
            const Text(
              'Titel:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 65,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Produkttitel eingeben...',
              ),
            ),
            const SizedBox(height: 16),
            
            // Price field
            const Text(
              'Preis (€):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0.00',
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 16),
            
            // Description field
            const Text(
              'Beschreibung:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Produktbeschreibung eingeben...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _postToKleinanzeigen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Anzeige aufgeben'),
              ),
            ),
            const SizedBox(height: 16),
                      ],
        ),
      ),
    );
  }
}
