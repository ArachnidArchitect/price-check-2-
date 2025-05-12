import 'package:flutter/material.dart';
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
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['results'] != null) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(data['results']);
            _sortProducts();
            _filteredProducts = List.from(_products);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid data format received';
            _isLoading = false;
          });
          print(_errorMessage);
        }
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
      
      // If this is a new search (not just typing), save the current position
      if (!wasSearching && _scrollController.hasClients) {
        _preSearchScrollPosition = _scrollController.position.pixels;
      }
      
      // Apply search filtering
      _filteredProducts = _products.where((product) {
        final String name = product['product_name']?.toString().toLowerCase() ?? '';
        final List<String> searchTerms = _searchQuery.split(' ');
        return searchTerms.every((term) => name.contains(term));
      }).toList();
      
      _noMatchFound = _filteredProducts.isEmpty;
      _isSearching = true;

      // Always scroll to top when starting a new search
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  // Function to show image in a modal
  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 100, color: Colors.white);
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.green, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                          controller: _scrollController,
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final String name = product['product_name']?.toString() ?? 'Unknown Product';
                            final String price = 'R${product['price']?.toString() ?? '0.00'}';
                            final String imageUrl = product['img']?.toString() ?? '';
                            final String logoUrl = product['logo']?.toString() ?? '';

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
                                  GestureDetector(
                                    onTap: imageUrl.isNotEmpty 
                                      ? () => _showImageModal(context, imageUrl)
                                      : null,
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
                                            },
                                          )
                                        : Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
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
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: _buildStoreLogo(logoUrl),
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
  
  Widget _buildStoreLogo(String logoUrl) {
    return Image.network(
      logoUrl,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.store, size: 24, color: Colors.grey[700]),
        );
      },
    );
  }
}