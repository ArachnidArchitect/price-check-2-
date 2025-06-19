import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListsScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ShoppingListsScreen({super.key, required this.productData});

  @override
  _ShoppingListsScreenState createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  List<String> shoppingList = [];
  List<String> categories = ["Weekly Essentials", "Braai Day"];
  Map<String, List<String>> categorizedShoppingList = {};
  TextEditingController _categoryController = TextEditingController();
  bool _isAddingCategory = false;  // Flag to show or hide the category input field
  bool _productAdded = false; // Flag to check if the product has been added

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  // Load shopping list and categories from SharedPreferences
  _loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      categories = prefs.getStringList('categories') ?? categories;

      // Decode the categorized shopping list from JSON
      List<String>? categorizedList = prefs.getStringList('categorizedShoppingList');
      if (categorizedList != null) {
        categorizedShoppingList = {};
        for (var item in categorizedList) {
          Map<String, dynamic> decoded = json.decode(item);
          String category = decoded['category'];
          List<String> items = List<String>.from(decoded['items']);
          categorizedShoppingList[category] = items;
        }
      }
    });
  }

  // Save shopping list and categories to SharedPreferences
  _saveShoppingList() async {
    final prefs = await SharedPreferences.getInstance();

    // Save categories list
    await prefs.setStringList('categories', categories);

    // Convert categorized shopping list to a list of strings
    List<String> categorizedList = categorizedShoppingList.entries.map((entry) {
      return json.encode({
        'category': entry.key,
        'items': entry.value,
      });
    }).toList();

    // Save the categorized shopping list
    await prefs.setStringList('categorizedShoppingList', categorizedList);
  }

  // Add a new category to the list
  _addNewCategory() {
    String newCategory = _categoryController.text.trim();
    if (newCategory.isNotEmpty && !categories.contains(newCategory)) {
      setState(() {
        categories.add(newCategory); // Add category to the list
        _isAddingCategory = false;  // Hide the input field after adding
      });
      _saveShoppingList(); // Save the updated categories
      _categoryController.clear(); // Clear the input field
    } else {
      // Optionally, show a message if category is empty or already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category already exists or is empty')),
      );
    }
  }

  // Add product to selected category
  _addToCategory(String category) {
    setState(() {
      String productJson = json.encode(widget.productData);
      if (categorizedShoppingList.containsKey(category)) {
        categorizedShoppingList[category]?.add(productJson);
      } else {
        categorizedShoppingList[category] = [productJson];
      }
      _productAdded = true; // Mark the product as added
    });
    _saveShoppingList();
  }

  // Delete a product from a category
  _deleteProduct(String category, String productJson) {
    setState(() {
      categorizedShoppingList[category]?.remove(productJson);
      if (categorizedShoppingList[category]?.isEmpty ?? true) {
        categorizedShoppingList.remove(category); // Remove the category if no products are left
      }
    });
    _saveShoppingList();
  }

  // Delete a category
  _deleteCategory(String category) {
    setState(() {
      categorizedShoppingList.remove(category);
      categories.remove(category);
    });
    _saveShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    // Extract product details from the passed data
    final String name = widget.productData['name']?.toString() ?? 'Unknown Product';
    final String price = widget.productData['price']?.toString() ?? 'Price not available';
    final String imageUrl = widget.productData['image']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Lists'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only show the product details if it hasn't been added yet
            !_productAdded ? Row(
              children: [
                // Product Image on the Left
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      )
                    : SizedBox.shrink(),

                // Product Details on the Right
                SizedBox(width: 16), // Space between image and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product: $name',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Price: $price',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ) : SizedBox.shrink(), // Hide the product details once added

            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Show a dialog with the list of categories
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Select a Category'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...categories.map((category) {
                                  return ListTile(
                                    title: Text(category),
                                    onTap: () {
                                      _addToCategory(category);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Add to Shopping List'),
                ),
                SizedBox(width: 16),
                // "Add New Category" button next to the "Add to Shopping List" button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingCategory = !_isAddingCategory;  
                    });
                  },
                  child: Text('Add New Category'),
                ),
              ],
            ),
            if (_isAddingCategory) ...[
              SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Enter a new category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addNewCategory,
                child: Text('Submit Category'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isAddingCategory = false;  // Hide the input field if cancel
                  });
                },
                child: Text('Cancel'),
              ),
            ],
            SizedBox(height: 16),
            // If categories are empty, show "The list is empty"
            (categories.isEmpty || categorizedShoppingList.isEmpty)
                ? Center(child: Text('The list is empty. Add a category to get started.'))
                : Column(
                    children: categories
                        .map((category) {
                          final categoryItems = categorizedShoppingList[category];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the category name
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteCategory(category);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // If the category has no items, show the "List is Empty" message
                              categoryItems == null || categoryItems.isEmpty
                                  ? Text('The list is empty.')
                                  : Column(
                                      children: categoryItems.map((productJson) {
                                        final product = json.decode(productJson);
                                        return ListTile(
                                          leading: product['image'] != null
                                              ? Image.network(
                                                  product['image'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                )
                                              : SizedBox.shrink(),
                                          title: Text(product['name']),
                                          subtitle: Text('Price: ${product['price']}'),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              _deleteProduct(category, productJson);
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
