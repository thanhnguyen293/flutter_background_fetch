import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_task.dart';
import 'logger_util.dart';

const eventKey = "fetch_events";

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<String> _events = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var prefs = await SharedPreferences.getInstance();
    var json = prefs.getString(eventKey);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
    }

    try {
      var status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        onBackgroundFetch,
        onBackgroundFetchTimeout,
      );
      logger.i('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });

      BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 10000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
      ));
    } on Exception catch (e) {
      logger.e("[BackgroundFetch] configure ERROR: $e");
    }

    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((status) {
        logger.i('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        logger.e('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((status) {
        logger.i('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    var status = await BackgroundFetch.status;
    logger.i('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });

    BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.transistorsoft.customtask",
      delay: 10000,
      periodic: false,
      forceAlarmManager: false,
      stopOnTerminate: false,
      enableHeadless: true,
    ));
  }

  void _onClickClear() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove(eventKey);
    setState(() {
      _events = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    const emptyText = Center(
      child: Text(
          'Waiting for fetch events. Simulate one.\n [Android] \$ ./scripts/simulate-fetch\n [iOS] XCode->Debug->Simulate Background Fetch'),
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BackgroundFetch Example',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
          foregroundColor: Colors.black,
          actions: <Widget>[
            Switch(value: _enabled, onChanged: _onClickEnable),
          ],
        ),
        body: (_events.isEmpty)
            ? emptyText
            : ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  var event = _events[index].split("@");
                  return InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(5.0),
                      labelStyle:
                          const TextStyle(color: Colors.blue, fontSize: 20.0),
                      labelText: "[${event[0].toString()}]",
                    ),
                    child: Text(
                      event[1],
                      style:
                          const TextStyle(color: Colors.black, fontSize: 16.0),
                    ),
                  );
                },
              ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _onClickStatus,
                  child: Text('Status: $_status'),
                ),
                ElevatedButton(
                  onPressed: _onClickClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   bool _enabled = true;
//   int _status = 0;
//   List<String> _events = [];
//
//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//   }
//
//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     // Load persisted fetch events from SharedPreferences
//     var prefs = await SharedPreferences.getInstance();
//     var json = prefs.getString(eventKey);
//     if (json != null) {
//       setState(() {
//         _events = jsonDecode(json).cast<String>();
//       });
//     }
//
//     // Configure BackgroundFetch.
//     try {
//       var status = await BackgroundFetch.configure(
//           BackgroundFetchConfig(
//               minimumFetchInterval: 15,
//               forceAlarmManager: false,
//               stopOnTerminate: false,
//               startOnBoot: true,
//               enableHeadless: true,
//               requiresBatteryNotLow: false,
//               requiresCharging: false,
//               requiresStorageNotLow: false,
//               requiresDeviceIdle: false,
//               requiredNetworkType: NetworkType.NONE),
//           _onBackgroundFetch,
//           _onBackgroundFetchTimeout);
//       print('[BackgroundFetch] configure success: $status');
//       setState(() {
//         _status = status;
//       });
//
//       // Schedule a "one-shot" custom-task in 10000ms.
//       // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
//       // where device must be powered (and delay will be throttled by the OS).
//       BackgroundFetch.scheduleTask(TaskConfig(
//           taskId: "com.transistorsoft.customtask",
//           delay: 10000,
//           periodic: false,
//           forceAlarmManager: true,
//           stopOnTerminate: false,
//           enableHeadless: true));
//     } on Exception catch (e) {
//       print("[BackgroundFetch] configure ERROR: $e");
//     }
//
//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;
//   }
//
//   void _onBackgroundFetch(String taskId) async {
//     var prefs = await SharedPreferences.getInstance();
//     var timestamp = DateTime.now();
//     // This is the fetch-event callback.
//     print("[BackgroundFetch] Event received: $taskId");
//     setState(() {
//       _events.insert(0, "$taskId@${timestamp.toString()}");
//     });
//     // Persist fetch events in SharedPreferences
//     prefs.setString(eventKey, jsonEncode(_events));
//
//     if (taskId == "flutter_background_fetch") {
//       // Perform an example HTTP request.
//       var url =
//           Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});
//
//       var response = await http.get(url);
//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
//         var itemCount = jsonResponse['totalItems'];
//         print('Number of books about http: $itemCount.');
//       } else {
//         print('Request failed with status: ${response.statusCode}.');
//       }
//     }
//     // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
//     // for taking too long in the background.
//     BackgroundFetch.finish(taskId);
//   }
//
//   /// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
//   void _onBackgroundFetchTimeout(String taskId) {
//     print("[BackgroundFetch] TIMEOUT: $taskId");
//     BackgroundFetch.finish(taskId);
//   }
//
//   void _onClickEnable(enabled) {
//     setState(() {
//       _enabled = enabled;
//     });
//     if (enabled) {
//       BackgroundFetch.start().then((status) {
//         print('[BackgroundFetch] start success: $status');
//       }).catchError((e) {
//         print('[BackgroundFetch] start FAILURE: $e');
//       });
//     } else {
//       BackgroundFetch.stop().then((status) {
//         print('[BackgroundFetch] stop success: $status');
//       });
//     }
//   }
//
//   void _onClickStatus() async {
//     var status = await BackgroundFetch.status;
//     print('[BackgroundFetch] status: $status');
//     setState(() {
//       _status = status;
//     });
//     // Invoke a scheduleTask for testing
//     BackgroundFetch.scheduleTask(TaskConfig(
//         taskId: "com.transistorsoft.customtask",
//         delay: 10000,
//         periodic: false,
//         forceAlarmManager: false,
//         stopOnTerminate: false,
//         enableHeadless: true));
//   }
//
//   void _onClickClear() async {
//     var prefs = await SharedPreferences.getInstance();
//     prefs.remove(eventKey);
//     setState(() {
//       _events = [];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const EMPTY_TEXT = Center(
//         child: Text(
//             'Waiting for fetch events.  Simulate one.\n [Android] \$ ./scripts/simulate-fetch\n [iOS] XCode->Debug->Simulate Background Fetch'));
//
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//             title: const Text('BackgroundFetch Example',
//                 style: TextStyle(color: Colors.black)),
//             backgroundColor: Colors.amberAccent,
//             foregroundColor: Colors.black,
//             actions: <Widget>[
//               Switch(value: _enabled, onChanged: _onClickEnable),
//             ]),
//         body: (_events.isEmpty)
//             ? EMPTY_TEXT
//             : Container(
//                 child: ListView.builder(
//                     itemCount: _events.length,
//                     itemBuilder: (context, index) {
//                       var event = _events[index].split("@");
//                       return InputDecorator(
//                           decoration: InputDecoration(
//                               contentPadding: EdgeInsets.only(
//                                   left: 5.0, top: 5.0, bottom: 5.0),
//                               labelStyle:
//                                   TextStyle(color: Colors.blue, fontSize: 20.0),
//                               labelText: "[${event[0].toString()}]"),
//                           child: Text(event[1],
//                               style: TextStyle(
//                                   color: Colors.black, fontSize: 16.0)));
//                     }),
//               ),
//         bottomNavigationBar: BottomAppBar(
//             child: Container(
//                 padding: EdgeInsets.only(left: 5.0, right: 5.0),
//                 child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: <Widget>[
//                       ElevatedButton(
//                           onPressed: _onClickStatus,
//                           child: Text('Status: $_status')),
//                       ElevatedButton(
//                           onPressed: _onClickClear, child: Text('Clear'))
//                     ]))),
//       ),
//     );
//   }
// }
