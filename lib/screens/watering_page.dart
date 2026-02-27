import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:cropmate/models/watering_schedule.dart';
import 'package:cropmate/widgets/growth_stage_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

class WateringPage extends StatefulWidget {
  const WateringPage({Key? key}) : super(key: key);

  @override
  _WateringPageState createState() => _WateringPageState();
}

class _WateringPageState extends State<WateringPage> {
  final List<WateringSchedule> _schedules = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSchedules();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? hasPermission =
          await androidPlugin?.areNotificationsEnabled();
      if (hasPermission == false) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Permission Required'),
            content: const Text(
                'To ensure you receive watering reminders at the correct time, please grant notification permissions.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await androidPlugin?.requestNotificationsPermission();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      tz_init.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {},
      );
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleNotification(WateringSchedule schedule) async {
    try {
      final int id = schedule.plant.hashCode;
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'watering_channel',
        'Watering Reminders',
        channelDescription: 'Notifications for plant watering reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      final scheduledDate = tz.TZDateTime.from(
        schedule.nextWatering.isAfter(DateTime.now())
            ? schedule.nextWatering
            : DateTime.now().add(const Duration(minutes: 1)),
        tz.local,
      );
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Time to water your ${schedule.plant}!',
          'Your ${schedule.plant} needs water today.',
          scheduledDate,
          platformChannelSpecifics,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (exactAlarmError) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Time to water your ${schedule.plant}!',
          'Your ${schedule.plant} needs water today.',
          scheduledDate,
          platformChannelSpecifics,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString('watering_schedules');
    if (schedulesJson != null) {
      final List<dynamic> decoded = jsonDecode(schedulesJson);
      setState(() {
        _schedules.clear();
        for (var item in decoded) {
          _schedules.add(WateringSchedule.fromJson(item));
        }
      });
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson =
        jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await prefs.setString('watering_schedules', schedulesJson);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Watering Schedule',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 22 : 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(isTablet),
          Expanded(
            child: _schedules.isEmpty
                ? _buildEmptyState(isTablet)
                : _buildScheduleList(isTablet),
          ),
        ],
      ),
      floatingActionButton: _schedules.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showAddScheduleDialog();
              },
              backgroundColor: Colors.blue[600],
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Plant',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 20,
        vertical: isTablet ? 20 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop,
                color: Colors.blue[400], size: isTablet ? 32 : 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep your plants healthy',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Track watering schedules and get reminders',
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 40 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isTablet ? 160 : 120,
              height: isTablet ? 160 : 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.water_drop_outlined,
                  size: isTablet ? 80 : 60, color: Colors.blue[300]),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              'No watering schedules yet',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 40),
              child: Text(
                'Add your first plant to start tracking when to water your plants',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: isTablet ? 17 : 15, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: isTablet ? 40 : 28),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showAddScheduleDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Plant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 36 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(bool isTablet) {
    // Grid for tablets, list for phones
    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _schedules.length,
        itemBuilder: (context, index) =>
            _buildScheduleCard(index, isTablet),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) => _buildScheduleCard(index, isTablet),
    );
  }

  Widget _buildScheduleCard(int index, bool isTablet) {
    final schedule = _schedules[index];
    final daysUntilWatering =
        schedule.nextWatering.difference(DateTime.now()).inDays;

    Color statusColor = Colors.blue;
    String statusText = 'Water in $daysUntilWatering days';
    if (daysUntilWatering <= 0) {
      statusColor = Colors.red;
      statusText = 'Water today!';
    } else if (daysUntilWatering == 1) {
      statusColor = Colors.orange;
      statusText = 'Water tomorrow';
    }

    return Card(
      margin: isTablet ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: statusColor, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isTablet ? 14 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant image
                Container(
                  width: isTablet ? 70 : 72,
                  height: isTablet ? 70 : 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: schedule.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(schedule.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.local_florist,
                          size: isTablet ? 36 : 36,
                          color: Colors.green[700]),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.plant,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (schedule.cropType != null)
                        _infoRow(Icons.grass, 'Crop: ${schedule.cropType}',
                            Colors.green[700]!, isTablet),
                      if (schedule.cropType != null &&
                          schedule.plantingDate != null &&
                          schedule.currentStageIndex != null)
                        GrowthStageWidget(
                          cropType: schedule.cropType!,
                          plantingDate: schedule.plantingDate!,
                          currentStageIndex: schedule.currentStageIndex!,
                        ),
                      if (schedule.cropType == null)
                        _infoRow(Icons.calendar_today,
                            'Frequency: ${schedule.frequency}',
                            Colors.grey[700]!, isTablet),
                      const SizedBox(height: 2),
                      _infoRow(Icons.history,
                          'Last: ${_formatDate(schedule.lastWatered)}',
                          Colors.grey[700]!, isTablet),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _waterPlant(index);
                    },
                    icon: const Icon(Icons.water_drop, size: 16),
                    label: Text('Water Now',
                        style: TextStyle(fontSize: isTablet ? 14 : 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showEditScheduleDialog(index);
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.grey[600],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _deleteSchedule(index);
                  },
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red[400],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: isTablet ? 13 : 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    final TextEditingController plantName = TextEditingController();
    String frequency = 'Every 7 days';
    File? selectedImage;
    String? selectedCropType;
    DateTime? plantingDate = DateTime.now();
    bool isCustomFrequency = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= 600;

          return Container(
            margin: isTablet
                ? EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.15, vertical: 40)
                : EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: isTablet ? 32 : 20,
              right: isTablet ? 32 : 20,
              top: 20,
              bottom: keyboardHeight + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Plant',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plantName,
                    decoration: InputDecoration(
                      labelText: 'Plant Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.eco, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Watering Frequency',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Every 3 days',
                      'Every 7 days',
                      'Every 14 days',
                      'Every 30 days',
                    ].map((label) {
                      final selected = frequency == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setDialogState(() => frequency = label);
                        },
                        selectedColor: Colors.blue[600],
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontSize: isTablet ? 14 : 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Plant Image (Optional)',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(
                            () => selectedImage = File(image.path));
                      }
                    },
                    child: Container(
                      height: isTablet ? 150 : 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(selectedImage!,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: isTablet ? 48 : 38,
                                    color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select an image',
                                  style: TextStyle(
                                      fontSize: isTablet ? 15 : 13,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 52 : 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (plantName.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a plant name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final newSchedule = WateringSchedule(
                          plant: plantName.text.trim(),
                          frequency: frequency,
                          lastWatered: DateTime.now(),
                          nextWatering: DateTime.now().add(
                            Duration(
                                days: int.parse(frequency.split(' ')[1])),
                          ),
                          imagePath: selectedImage?.path,
                          cropType: selectedCropType,
                          plantingDate: plantingDate,
                          currentStageIndex: 0,
                        );
                        setState(() => _schedules.add(newSchedule));
                        _saveSchedules();
                        _scheduleNotification(newSchedule);
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(
                            fontSize: isTablet ? 17 : 15,
                            fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Add Schedule'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _waterPlant(int index) {
    final schedule = _schedules[index];
    final updatedSchedule = schedule.copyWith(
      lastWatered: DateTime.now(),
      nextWatering: DateTime.now().add(
        Duration(days: int.parse(schedule.frequency.split(' ')[1])),
      ),
    );
    setState(() => _schedules[index] = updatedSchedule);
    _saveSchedules();
    _scheduleNotification(updatedSchedule);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${schedule.plant} has been watered!'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
            label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
    HapticFeedback.mediumImpact();
  }

  void _showEditScheduleDialog(int index) {
    // Implement edit schedule functionality
  }

  void _deleteSchedule(int index) {
    setState(() => _schedules.removeAt(index));
    _saveSchedules();
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}