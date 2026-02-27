import 'dart:io' show File;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cropmate/screens/plant_identification_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({Key? key}) : super(key: key);

  @override
  _PlantsPageState createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  @override
  void initState() {
    super.initState();
    _loadSavedPlants();
  }

  Future<void> _loadSavedPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plantsJson = prefs.getString('identified_plants');

      if (plantsJson != null) {
        final List<dynamic> decodedPlants = jsonDecode(plantsJson);

        // Clear existing plants and add the loaded ones
        PlantCollection.instance.plants.clear();
        for (var plantData in decodedPlants) {
          PlantCollection.instance.plants.add(Plant.fromJson(plantData));
        }

        // Update the UI
        setState(() {});
      }
    } catch (e) {
      print('Error loading plants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = PlantCollection.instance.plants;

    return Scaffold(
      backgroundColor: Colors.white,
      body: plants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_florist_outlined,
                    size: 80,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No plants in your collection yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Identify plants to add them to your collection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const PlantIdentificationPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            var curve = Curves.easeOutBack;
                            var curveTween = CurveTween(curve: curve);

                            var fadeAnimation = Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(animation.drive(curveTween));

                            var scaleAnimation = Tween<double>(
                              begin: 0.5,
                              end: 1.0,
                            ).animate(animation.drive(curveTween));

                            return FadeTransition(
                              opacity: fadeAnimation,
                              child: ScaleTransition(
                                scale: scaleAnimation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      ).then((_) {
                        // Reload plants when returning from identification page
                        _loadSavedPlants();
                      });
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Identify Plants'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return _buildPlantCard(plant);
              },
            ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: plant.imagePath != null
                ? Image.file(
                    File(plant.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackImage(plant);
                    },
                  )
                : _buildFallbackImage(plant),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(plant.confidence * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Added on: ${_formatDate(plant.dateAdded)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(Plant plant) {
    return plant.referenceImage.isNotEmpty
        ? Image.network(
            plant.referenceImage,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: Colors.green.withOpacity(0.1),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
              );
            },
          )
        : Container(
            height: 180,
            color: Colors.green.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.green,
                size: 50,
              ),
            ),
          );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
