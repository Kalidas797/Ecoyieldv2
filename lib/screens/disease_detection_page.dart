import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

class DiseaseDetectionPage extends StatefulWidget {
  const DiseaseDetectionPage({Key? key}) : super(key: key);

  @override
  _DiseaseDetectionPageState createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage>
    with SingleTickerProviderStateMixin {
  String? _result;
  File? _image;
  bool _isLoading = false;
  List<dynamic>? _detections;
  double? _imageWidth;
  double? _imageHeight;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final ImagePicker _picker = ImagePicker();

  // Roboflow API credentials
  final String _apiUrl = "https://detect.roboflow.com";
  final String _apiKey = "gju4pW2eYxLCzzlRxi8s";
  final String _modelId = "plant-disease-detection-v2-2nclk/1";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    // Add haptic feedback when selecting image source
    HapticFeedback.mediumImpact();

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      // Add haptic feedback when image is selected
      HapticFeedback.selectionClick();

      // Decode image to get dimensions
      final bytes = await pickedFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      setState(() {
        _image = File(pickedFile.path);
        _imageWidth = decodedImage.width.toDouble();
        _imageHeight = decodedImage.height.toDouble();
        _result = null;
        _detections = null;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> detectDisease() async {
    // Add haptic feedback when detect button is pressed
    HapticFeedback.heavyImpact();

    if (_image == null) {
      // Add error haptic feedback
      HapticFeedback.vibrate();
      setState(() {
        _result = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _detections = null;
    });

    try {
      // Create multipart request
      var request = http.MultipartRequest(
          'POST', Uri.parse('$_apiUrl/$_modelId?api_key=$_apiKey'));

      // Add image file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response
        var jsonResponse = json.decode(response.body);
        print('API Response: $jsonResponse');

        if (jsonResponse['predictions'] != null) {
          _detections = jsonResponse['predictions'];

          if (_detections!.isEmpty) {
            // Add success haptic feedback for healthy plant
            HapticFeedback.lightImpact();
            setState(() {
              _result = 'Make sure u take a clear photo of a plant';
              _isLoading = false;
            });
            if (mounted) {
              _showResultDialog(isHealthy: true);
            }
          } else {
            // Add warning haptic feedback for disease detection
            HapticFeedback.mediumImpact();

            // Sort predictions by confidence
            _detections!.sort((a, b) => (b['confidence'] as double)
                .compareTo(a['confidence'] as double));

            // Get the highest confidence prediction
            var topPrediction = _detections![0];
            var className = topPrediction['class'];
            var confidence = topPrediction['confidence'] * 100;

            setState(() {
              _result = 'Confidence: ${confidence.toStringAsFixed(2)}%\n\n'
                  'Please consult with a plant specialist for accurate diagnosis.';
              _isLoading = false;
            });
            if (mounted) {
              _showResultDialog(isHealthy: false, diseaseName: className);
            }
          }
        } else {
          setState(() {
            _result = 'Could not process detection results';
            _isLoading = false;
          });
          if (mounted) {
            _showErrorDialog('Could not process detection results');
          }
        }
      } else {
        setState(() {
          _result = 'Error: ${response.statusCode} - ${response.reasonPhrase}';
          _isLoading = false;
        });
        if (mounted) {
          _showErrorDialog(
              'Error: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      print('Error during disease detection: $e');
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    }
  }

  void _showResultDialog({required bool isHealthy, String? diseaseName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: isHealthy ? Colors.green : Colors.orange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  isHealthy
                      ? 'No disease detected !'
                      : (diseaseName ?? 'Disease Detected'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isHealthy
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                // Result details
                Text(
                  _result!,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHealthy
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),

                // Error message
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Disease Detection',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _animation,
                // child: const Text(
                //   'Plant Disease Detection',
                //   style: TextStyle(
                //       color: Colors.green,
                //       fontSize: 28,
                //       fontWeight: FontWeight.bold,
                //       letterSpacing: 0.5),
                //   textAlign: TextAlign.left,
                // ),
              ),
              const SizedBox(height: 5),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_animation),
                child: Column(
                  children: [
                    const Text(
                      'Plant Disease Identification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Take or select a photo of a plant to identify it',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Image preview
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _image == null
                    ? Center(
                        child: FadeTransition(
                          opacity: _animation,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 90, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No image selected',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                              SizedBox(height: 8),
                              Text(
                                'Tap the buttons below to add a photo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _imageWidth,
                            height: _imageHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _image!,
                                  fit: BoxFit.fill,
                                ),
                                if (_detections != null)
                                  CustomPaint(
                                    painter: BoundingBoxPainter(
                                      _detections!,
                                      _imageWidth!,
                                      _imageHeight!,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Image selection buttons
              const SizedBox(height: 24),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_animation),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Take Photo Button
                    Column(
                      children: [
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _getImage(ImageSource.camera),
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Gallery Button
                    Column(
                      children: [
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _getImage(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(24),
                              child: Center(
                                child: Icon(
                                  Icons.photo_library,
                                  color: Colors.purple,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detect button
              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(_animation),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _image == null ? null : detectDisease,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Detect Disease',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Results
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter(this.detections, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final textPaint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.fill;

    for (var detection in detections) {
      // Get normalized coordinates (0-1 range)
      final x = detection['x'] as double;
      final y = detection['y'] as double;
      final width = detection['width'] as double;
      final height = detection['height'] as double;

      // Calculate the coordinates within the container
      final left = (x - width / 2) * size.width;
      final top = (y - height / 2) * size.height;
      final right = (x + width / 2) * size.width;
      final bottom = (y + height / 2) * size.height;

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      // Draw label background
      final className = detection['class'] as String;
      final confidence = (detection['confidence'] as double) * 100;
      final label = '$className ${confidence.toStringAsFixed(0)}%';

      final textStyle = const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(
        text: label,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw label background
      final textBackgroundRect = Rect.fromLTWH(
        left,
        top > 20 ? top - 20 : top,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(textBackgroundRect, textPaint);

      // Draw text
      textPainter.paint(
        canvas,
        Offset(
          left + 4,
          top > 20 ? top - 18 : top + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
