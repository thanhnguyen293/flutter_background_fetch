import 'dart:async';
import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'logger_util.dart';

const eventKey = "fetch_events";

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  var timeout = task.timeout;

  if (timeout) {
    logger.e("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  logger.i("[BackgroundFetch] Headless event received: $taskId");

  var timestamp = DateTime.now();
  var prefs = await SharedPreferences.getInstance();
  var events = <String>[];
  var json = prefs.getString(eventKey);
  if (json != null) {
    events = jsonDecode(json).cast<String>();
  }
  events.insert(0, "$taskId@$timestamp [Headless]");
  prefs.setString(eventKey, jsonEncode(events));

  if (taskId == 'flutter_background_fetch') {
    BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: false,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
    );
  }
  BackgroundFetch.finish(taskId);
}

void onBackgroundFetchTimeout(taskId) {
  logger.w("[BackgroundFetch] TIMEOUT: $taskId");
  BackgroundFetch.finish(taskId);
}

Future<void> onBackgroundFetch(String taskId) async {
  var prefs = await SharedPreferences.getInstance();
  var timestamp = DateTime.now();
  logger.i("[BackgroundFetch] Event received: $taskId");

  var events = <String>[];
  var json = prefs.getString(eventKey);
  if (json != null) {
    events = jsonDecode(json).cast<String>();
  }
  events.insert(0, "$taskId@$timestamp");
  prefs.setString(eventKey, jsonEncode(events));

  if (taskId == "flutter_background_fetch") {
    var url =
        Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      var itemCount = jsonResponse['totalItems'];
      logger.i('Number of books about http: $itemCount.');
    } else {
      logger.e('Request failed with status: ${response.statusCode}.');
    }
  }
  BackgroundFetch.finish(taskId);
}
