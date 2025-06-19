import 'package:flutter/material.dart';
import 'shopping_lists_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _noMatchFound = false;
  
  // Scroll controller and position tracking
  final ScrollController _scrollController = ScrollController();
  double _preSearchScrollPosition = 0.0;
  bool _isSearching = false;
  
  // Sort options
  bool _sortByPriceAscending = true;
  bool _sortAlphabetically = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse('https://lifechoices-scrapper.onrender.com/store/products');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((item) => item as Map<String, dynamic>).toList();
          
          _products.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));

          _filteredProducts = List.from(_products);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load products: ${response.statusCode}';
          _isLoading = false;
        });
        print(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching products: $e';
        _isLoading = false;
      });
      print(_errorMessage);
    }
  }

  void _sortProducts() {
    // Sort products alphabetically first
    _products.sort((a, b) {
      final String nameA = a['product_name']?.toString().toLowerCase() ?? '';
      final String nameB = b['product_name']?.toString().toLowerCase() ?? '';
      return nameA.compareTo(nameB);
    });

    // Then sort by price if not sorting alphabetically
    if (!_sortAlphabetically) {
      _products.sort((a, b) {
        final double priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
        final double priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
        return _sortByPriceAscending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
      });
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortByPriceAscending = !_sortByPriceAscending;
      _sortProducts();
      _performSearch(_searchQuery); // Re-apply search filter with new sort
    });
  }

  void _toggleSortType() {
    setState(() {
      _sortAlphabetically = !_sortAlphabetically;
      _sortProducts();
      _performSearch(_searchQuery); // Re-apply search filter with new sort
    });
  }

  void _performSearch(String query) {
    setState(() {
      final wasSearching = _searchQuery.isNotEmpty;
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredProducts = List.from(_products);
        _noMatchFound = false;
        _isSearching = false;
        
        // Restore scroll position when search is cleared
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_preSearchScrollPosition);
          }
        });
        
        return;
      }
      
      // Apply strict search filtering
      _filteredProducts = _products.where((product) {
        final String name = product['name']?.toString().toLowerCase() ?? '';
        
        final List<String> searchTerms = _searchQuery.split(' ');
        final List<String> productWords = name.split(' ');
        
        return searchTerms.any((term) => 
          productWords.any((word) => word == term)
        );
      }).toList();

      _noMatchFound = _filteredProducts.isEmpty;
    });
  }

  // Function to determine store from image URL or product name
  String determineStore(String imageUrl, String name) {
    // Extract store from image URL
    if (imageUrl.contains('woolworths')) {
      return 'woolworths';
    } else if (imageUrl.contains('checkers')) {
      return 'checkers';
    } else if (imageUrl.contains('shoprite')) {
      return 'shoprite';
    } else if (imageUrl.contains('pick-n-pay') || imageUrl.contains('picknpay')) {
      return 'picknpay';
    } else if (imageUrl.contains('spar')) {
      return 'spar';
    }
    
    // Default store if we can't determine
    return 'default';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'ECHO',
              style: TextStyle(
                color: Color(0xFF00BF63),
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontFamily: 'Roboto Condensed',
                fontSize: 28,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find the Best Prices, Right Now!',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Image.network(
              'https://leahbasson.github.io/MyImages/projects/store-logos.png',
              fit: BoxFit.contain,
              height: 50,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              cursorColor: Colors.black,
              style: GoogleFonts.poppins(),
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'e.g Full cream milk',
                hintStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(
                    color: Color(0xFF00BF63),
                    width: 2.0,
                  ),
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF00BF63)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Color(0xFF00BF63)),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(
                    color: Color(0xFF00BF63),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(
                    color: Color(0xFF00BF63),
                    width: 2.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Sort by: ',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _toggleSortType,
                  icon: Icon(_sortAlphabetically ? Icons.sort_by_alpha : Icons.attach_money, size: 18),
                  label: Text(
                    _sortAlphabetically ? 'A-Z' : 'Price',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF00BF63),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
                if (!_sortAlphabetically) 
                  IconButton(
                    onPressed: _toggleSortOrder,
                    icon: Icon(
                      _sortByPriceAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                    ),
                    color: Color(0xFF00BF63),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF00BF63)))
                  : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: GoogleFonts.poppins(color: Colors.red)))
                    : _noMatchFound
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Product not found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try a different search term',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final data = _filteredProducts[index];
                            final String name = data['name']?.toString() ?? 'Unknown Product';
                            final String price = data['price']?.toString() ?? 'Price not available';
                            final String imageUrl = data['image']?.toString() ?? '';
                            final String store = determineStore(imageUrl, name);

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF00BF63),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        price,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00BF63),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    child: _buildStoreLogo(store),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoreLogo(String store) {
    final Map<String, String> storeAssets = {
      'woolworths': 'assets/store_logos/woolworths.png',
      'checkers': 'assets/store_logos/checkers.png',
      'shoprite': 'assets/store_logos/shoprite.png',
      'picknpay': 'assets/store_logos/picknpay.png',
      'spar': 'assets/store_logos/spar.png',
      'default': 'assets/store_logos/default.png',
    };
    
    String assetPath = storeAssets[store] ?? storeAssets['default']!;
    
    Container fallbackIcon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.store, size: 24, color: Colors.grey[700]),
    );
    
    return Image.asset(
      assetPath,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return fallbackIcon;
      },
    );
  }
}