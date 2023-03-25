//flutter app to run on an android watch, which can collect data from a sensor
//and trains a model on the data collected
//the model is then used to predict the activity of the user
import 'package:flutter/material.dart';
import 'package:health/health.dart';
//import a package to train an ML model on flutter
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';

void main() {
  runApp(const MyApp());
}

Future<List> fetchData(int a) async {
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
  DateTime startDate = endDate.subtract(Duration(hours: 10));
  List listA = await health.getHealthDataFromTypes(startDate, endDate, types);
  int a = 0;

  //get this matrix
  List<double> initial_coef = [0.0, 0.0, 0.0, 0.0];
  //append the integer a at the end of our data listA
  listA.add(a);
  // Do something with the data
  //train function goes here
  final vec = Vector.fromList(initial_coef);

  final initial_vec = Matrix.fromColumns([vec]);

  final features = DataFrame([['spo2', 'gluc', 'bps', 'bpd', 'label'], listA]);

  final model = LinearRegressor.SGD(features, 'label', fitIntercept: false, initialCoefficients: initial_vec);

  initial_coef = model.coefficients.toList();
  //write the matrix back
  return listA;
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
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () {
                        // Respond to button press
                        fetchData(1);
                      },
                      child: Text('Yes'),
                    )),

                Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () {
                        // Respond to button press
                        fetchData(0);
                      },
                      child: Text('No'),
                    ))
              ]
            )
          ],
        ),
      ),
      //floatingActionButton: FloatingActionButton(
        //onPressed: _incrementCounter,
        //tooltip: 'Increment',
        //child: const Icon(Icons.add),
      //), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}