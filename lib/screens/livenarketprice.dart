import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import this

class LivePrice extends StatefulWidget {
  const LivePrice({Key? key}) : super(key: key);

  @override
  State<LivePrice> createState() => _LivePriceState();
}

class _LivePriceState extends State<LivePrice> {
  bool _isLoading = true;
  List<dynamic> _marketData = [];
  String _errorMessage = '';

  final String apiUrl =
      "https://ecoyieldbackend-production.up.railway.app/api/prices";
  final String cacheKey = "cached_market_prices"; // Key for local storage

  @override
  void initState() {
    super.initState();
    _fetchMarketData(); // Will try cache first
  }

  // Added a forceRefresh parameter. 
  // false = check cache first. true = skip cache and hit API.
  Future<void> _fetchMarketData({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check Cache (if we aren't forcing a refresh)
      if (!forceRefresh) {
        final cachedString = prefs.getString(cacheKey);
        if (cachedString != null) {
          final decoded = jsonDecode(cachedString);
          if (mounted) {
            setState(() {
              _marketData = decoded["data"];
              _isLoading = false;
            });
          }
          return; // Exit early so we don't hit the API
        }
      }

      // 2. If no cache or forceRefresh is true, fetch from API
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Save the raw JSON string to cache for next time
        await prefs.setString(cacheKey, response.body);

        final decoded = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _marketData = decoded["data"];
            _isLoading = false;
            _errorMessage = ''; // Clear any previous errors
          });
        }
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market Prices'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : RefreshIndicator(
                  // Trigger a forced API call when the user pulls to refresh
                  onRefresh: () => _fetchMarketData(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _marketData.length,
                    itemBuilder: (context, index) {
                      final item = _marketData[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["commodity"] ?? "",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildPriceColumn(
                                      "Min", item["min_price"]),
                                  _buildPriceColumn(
                                      "Modal", item["modal_price"]),
                                  _buildPriceColumn(
                                      "Max", item["max_price"]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildPriceColumn(String label, String? price) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          "₹ ${price ?? ''}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}