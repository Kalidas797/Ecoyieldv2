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

// import 'package:app_settings/app_settings.dart';
// import 'package:cropmatez/models/crop_watering_plan.dart';
// import 'package:cropmatez/widgets/growth_stage_widget.dart';

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
            title: const Text('Permission Required'),
            content: const Text(
                'To ensure you receive watering reminders at the correct time, please grant notification permissions.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await androidPlugin?.requestNotificationsPermission();
                },
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
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification tap
        },
      );
    } catch (e) {
      print('Error initializing notifications: $e');
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
        print('Falling back to inexact alarm: $exactAlarmError');
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
      print('Error scheduling notification: $e');
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Watering Schedule',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Icon(
                  Icons.water_drop,
                  color: Colors.blue[400],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep your plants healthy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track watering schedules and get reminders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _schedules.isEmpty ? _buildEmptyState() : _buildScheduleList(),
          ),
        ],
      ),
      // Only show the floating action button when there's at least one plant
      floatingActionButton: _schedules.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showAddScheduleDialog();
              },
              backgroundColor: Colors.blue[600],
              icon: const Icon(Icons.add),
              label: const Text('Add Plant'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No watering schedules yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add your first plant to start tracking when to water your plants',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
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
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                          : Icon(
                              Icons.local_florist,
                              size: 40,
                              color: Colors.green[700],
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.plant,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (schedule.cropType != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.grass,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Crop: ${schedule.cropType}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          if (schedule.cropType != null &&
                              schedule.plantingDate != null &&
                              schedule.currentStageIndex != null)
                            GrowthStageWidget(
                              cropType: schedule.cropType!,
                              plantingDate: schedule.plantingDate!,
                              currentStageIndex: schedule.currentStageIndex!,
                            ),
                          if (schedule.cropType == null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Frequency: ${schedule.frequency}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last watered: ${_formatDate(schedule.lastWatered)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _waterPlant(index);
                      },
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Water Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _showEditScheduleDialog(index);
                      },
                      icon: const Icon(Icons.edit),
                      color: Colors.grey[600],
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _deleteSchedule(index);
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red[400],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddScheduleDialog() {
    final TextEditingController plantName = TextEditingController();
    String frequency = 'Every 7 days';
    File? selectedImage;
    String? selectedCropType;
    DateTime? plantingDate = DateTime.now();
    bool isCustomFrequency = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Plant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: plantName,
                      decoration: InputDecoration(
                        labelText: 'Plant Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.eco),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Replace Flexible with a more appropriate solution
                    // DropdownButtonFormField<String>(
                    //   isExpanded:
                    //       true, // This ensures the dropdown fits within its container
                    //   decoration: InputDecoration(
                    //     labelText: 'Crop Type (Optional)',
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     prefixIcon: const Icon(Icons.grass),
                    //   ),
                    //   value: selectedCropType,
                    //   hint: const Text('Select crop type for specific care'),
                    //   items: [
                    //     const DropdownMenuItem<String>(
                    //       value: null,
                    //       child: Text('Custom Schedule'),
                    //     ),
                    //     ...CropWateringPlan.getDefaultPlans().map((plan) {
                    //       return DropdownMenuItem<String>(
                    //         value: plan.cropName,
                    //         child: Text(plan.cropName),
                    //       );
                    //     }).toList(),
                    //   ],
                    //   onChanged: (value) {
                    //     setState(() {
                    //       selectedCropType = value;
                    //       isCustomFrequency = value == null;
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    if (isCustomFrequency)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Watering Frequency',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFrequencyChip('Every 3 days', frequency,
                                  (val) {
                                setState(() => frequency = val);
                              }),
                              _buildFrequencyChip('Every 7 days', frequency,
                                  (val) {
                                setState(() => frequency = val);
                              }),
                              _buildFrequencyChip('Every 14 days', frequency,
                                  (val) {
                                setState(() => frequency = val);
                              }),
                              _buildFrequencyChip('Every 30 days', frequency,
                                  (val) {
                                setState(() => frequency = val);
                              }),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Image selection
                    const Text(
                      'Plant Image (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image =
                            await picker.pickImage(source: ImageSource.gallery);

                        if (image != null) {
                          setState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to select an image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (plantName.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a plant name'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final newSchedule = WateringSchedule(
                          plant: plantName.text,
                          frequency: frequency,
                          lastWatered: DateTime.now(),
                          nextWatering: DateTime.now().add(
                            Duration(
                              days: int.parse(frequency.split(' ')[1]),
                            ),
                          ),
                          imagePath: selectedImage?.path,
                          cropType: selectedCropType,
                          plantingDate: plantingDate,
                          currentStageIndex: 0,
                        );

                        // Add the schedule to the list
                        setState(() {
                          _schedules.add(newSchedule);
                        });

                        _saveSchedules();
                        _scheduleNotification(newSchedule);

                        // Close the dialog
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Schedule'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(
      String label, String selected, ValueChanged<String> onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == label,
      onSelected: (bool selected) {
        if (selected) {
          onSelected(label);
        }
      },
      selectedColor: Colors.blue[600],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: selected == label ? Colors.white : Colors.black,
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

    setState(() {
      _schedules[index] = updatedSchedule;
    });

    _saveSchedules();
    _scheduleNotification(updatedSchedule);

    // Show confirmation to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${schedule.plant} has been watered!'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // Add haptic feedback for confirmation
    HapticFeedback.mediumImpact();
  }

  void _showEditScheduleDialog(int index) {
    // Implement edit schedule functionality
  }

  void _deleteSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });

    _saveSchedules();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
