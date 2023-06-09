//flutter app to run on an android watch, which can collect data from a sensor
//and trains a model on the data collected
//the model is then used to predict the activity of the user

import 'dart:ui';
import 'dart:async';
import 'dart:html';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';


//import health package
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';
import 'package:health/health.dart';
import 'package:wear/wear.dart';
import 'firebase_options.dart';

FirebaseDatabase database = FirebaseDatabase.instance;


const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', //id
  'High Importance Notifications',   //title
  importance: Importance.high,
  playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
  FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async{
  await Firebase.initializeApp();
  print('A bg message just showed up : ${message.messageId}'); 
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
    );    
  runApp(const MyApp());
}

Future<void> fetchData(int a) async {
  List<HealthDataType> types = [
    //get blood oxygen data
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  HealthFactory health = HealthFactory();

  // Request authorization to access health data
  await health.requestAuthorization(types);

  // Fetch the SPO2 and BP data for the past week
  DateTime endDate = DateTime.now();
  DateTime startDate = endDate.subtract(const Duration(hours: 10));
  List listA = await health.getHealthDataFromTypes(startDate, endDate, types);
  int a=0;
  // Do something with the data
  //train function goes here
    //get this matrix
  List<double> initialCoef = await getStringDataFromFirebase();
  
  //append the integer a at the end of our data listA

  listA.add(a);
  // Do something with the data
  //train function goes here
  final vec = Vector.fromList(initialCoef);

  final initialVec = Matrix.fromColumns([vec]);

  final features = DataFrame([['spo2', 'gluc', 'bps', 'bpd', 'label'], listA]);

  final model = LinearRegressor.SGD(features, 'label', fitIntercept: false, initialCoefficients: initialVec);

  initialCoef = model.coefficients.toList();
  String singleLineString = matrixToSingleLineString(initialCoef);
  storeMatrix(singleLineString);

  //write the matrix back
  
}
Future<void> storeMatrix(String matrix) async {
  try {
    await FirebaseFirestore.instance.collection('matrices').doc('matrix1').set({
      'matrix': matrix,
    });
    print('Matrix stored successfully');
  } catch (error) {
    print('Error storing matrix: $error');
  }
}
String matrixToSingleLineString(List<double> matrix) {
  String result = '';
  for (int i = 0; i < matrix.length; i++) {
      result += '${matrix[i]} ';
    }
  return result.trim();
}
List<double> singleLineStringToMatrix(String singleLineString) {
  List<double> matrix = [];
  List<String> elements = singleLineString.trim().split(' ');
  int numRows = elements.length ~/ 3;
  for (int i = 0; i < numRows; i++) {
    List<String> row = elements.toList();
    matrix.add(row as double);
  }
  return matrix;
}
Future<List<double>> getStringDataFromFirebase() async {
  final collectionReference = FirebaseFirestore.instance.collection('matrices');
  final documentSnapshot = await collectionReference.doc('matrix1').get();

  // Parse the string data into a matrix
  final matrixString = documentSnapshot.data()!['matrix'] as String;
  final matrix = singleLineStringToMatrix(matrixString);
  return matrix;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Sleep Apnea Detection'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  // doc ids
  List<String> docIDs=[];
  
  Future getDocId() async{
    await FirebaseFirestore.instance.collection('matrices').get();

  }
  @override
  void initState(){
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if(notification!= null && android!= null){
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                //channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            )
          );
      }
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message){
        print('A new OnMessageOpened App event was published!');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if(notification!=null && android !=null){
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title?? ''),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body?? ''),
                    ],
                  ),
                   ),
              );
            });
        }
    });
  }

  void showNotifications() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    flutterLocalNotificationsPlugin.show(0,
      "Testing $_counter",
      "How you doin?",
      NotificationDetails(
        android : AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.high,
          color: Colors.blue,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        )
      ));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Have you undergone an episode of Sleep Apnea ?',
              style: TextStyle(fontSize: 30),
            ),
            //Text(
            //  '$_counter',
            //  style: Theme.of(context).textTheme.headline4,
            //),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () async {
                        fetchData(1);
                        },        
                      child: const Text('Yes'),
                    )),

                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () async {
                        // Respond to button press
                        //fetchData();
                        fetchData(0);  
                      },
                      child: const Text('No'),
                    ))
              ]
            )
          ],
        ),
      ),
      );
  }
}
