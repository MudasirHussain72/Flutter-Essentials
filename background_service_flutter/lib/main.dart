import 'dart:convert';
import 'dart:io';
import 'package:background_service_flutter/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize Firebase for background tasks
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Sync data with Firebase
    await syncPendingDataWithFirebase();
    return Future.value(true);
  });
}

Future<void> syncPendingDataWithFirebase() async {
  try {
    // Check for internet connection
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      String? unsyncedData = prefs.getString('unsyncedData');

      if (unsyncedData != null) {
        final List<dynamic> dataList = jsonDecode(unsyncedData);

        // Save all data items to Firestore
        final firestore = FirebaseFirestore.instance;
        for (var data in dataList) {
          if (data['needToSyncOnServer'] == true) {
            await firestore.collection('unsynced_data').add(data);
            data['needToSyncOnServer'] = false; // Mark as synced
          }
        }

        // Update local storage
        await prefs.setString('unsyncedData', jsonEncode(dataList));

        showNotification("Sync Successful",
            "All pending data has been synced successfully!");
      }
    }
  } catch (e) {
    print("Error during sync: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(); // Initialize Firebase
  AwesomeNotifications().initialize(
    null, // Default icon
    [
      NotificationChannel(
        channelKey: 'sync_channel',
        channelName: 'Data Sync Notifications',
        channelDescription: 'Notification channel for syncing data',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  Workmanager().initialize(callbackDispatcher); // Initialize WorkManager
  scheduleSyncTask(); // Schedule periodic sync task

  runApp(const MyApp());
}

void scheduleSyncTask() {
  Workmanager().registerPeriodicTask(
    "syncTask",
    "syncSharedPreferences",
    frequency: const Duration(minutes: 15), // Adjust to your needs
    constraints: Constraints(
      networkType: NetworkType.connected, // Requires internet
    ),
  );
}

Future<void> saveDataLocally(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();

  // Retrieve existing unsynced data
  String? existingData = prefs.getString('unsyncedData');
  List<dynamic> dataList =
      existingData != null ? jsonDecode(existingData) : <dynamic>[];

  // Add the new data with "needToSyncOnServer" flag
  data['needToSyncOnServer'] = true;
  dataList.add(data);

  // Save updated data back to local storage
  await prefs.setString('unsyncedData', jsonEncode(dataList));
  showNotification(
      "Data Saved Locally", "Your data has been saved locally for syncing.");
}

Future<void> showNotification(String title, String body) async {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, // Unique ID for this notification
      channelKey: 'sync_channel',
      title: title,
      body: body,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sync Data Example',
      home: SyncHomePage(),
    );
  }
}

class SyncHomePage extends StatefulWidget {
  SyncHomePage({super.key});

  @override
  State<SyncHomePage> createState() => _SyncHomePageState();
}

class _SyncHomePageState extends State<SyncHomePage> {
  final TextEditingController _dataController = TextEditingController();
  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then(
      (value) {
        if (!value) {
          AwesomeNotifications().requestPermissionToSendNotifications();
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Data Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dataController,
              decoration:
                  const InputDecoration(labelText: "Enter data to sync"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_dataController.text.isNotEmpty) {
                  Map<String, dynamic> data = {
                    'timestamp': DateTime.now().toIso8601String(),
                    'content': _dataController.text,
                  };
                  await saveDataLocally(data);
                  await syncPendingDataWithFirebase(); // Attempt immediate sync
                }
              },
              child: const Text("Save Data"),
            ),
          ],
        ),
      ),
    );
  }
}
