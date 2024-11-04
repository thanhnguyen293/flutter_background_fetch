import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'background_task.dart';

void main() {
  runApp(const MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}
