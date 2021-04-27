import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;
  bool _error = false;

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }

    return MyApp();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Laundry Box Courier'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

List<String> laundryType = [
  "Reguler 3 Hari ",
  "Reguler 2 Hari ",
  "Express 1 Hari ",
  "Express 12 Jam ",
  "Express 4 Jam"
];
List<String> laundryPackage = [
  "Cuci + Kering + Lipat",
  "Cuci + Kering + Setrika + Lipat",
  "Setrika + Lipat"
];

class _MyHomePageState extends State<MyHomePage> {
  CollectionReference users =
      FirebaseFirestore.instance.collection('laundries');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
          stream: users.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading");
            }

            return ListView(
              children: snapshot.data.docs.map((DocumentSnapshot document) {
                final dateFormat = new DateFormat('dd MMMM yyyy hh:mm');

                return ListTile(
                  title: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(laundryType[document.data()['laundry_type']]),
                  ),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${laundryPackage[document.data()['laundry_package']]} (${document.data()['weight']} kg)",
                      ),
                      SizedBox(height: 7.5),
                      Text(
                        dateFormat.format(
                            new DateTime.fromMillisecondsSinceEpoch(
                                document.data()['created_at'])),
                      ),
                      SizedBox(height: 7.5),
                      GestureDetector(
                        onTap: () async {
                          String _url =
                              "https://www.google.com/maps/search/?api=1&query=${document.data()['geo']['lat']},${document.data()['geo']['lng']}";
                          await canLaunch(_url)
                              ? await launch(_url)
                              : throw 'Could not launch $_url';
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Lihat Lokasi Pelanggan',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 7.5),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              document.data()['status'] == 'received'
                                  ? Colors.blue
                                  : Colors.green),
                        ),
                        onPressed: () async {
                          await HttpClient().postUrl(Uri.parse(
                              "https://laundry-box-iot.herokuapp.com/confirm"));

                          await users
                              .doc(document.id)
                              .update({"status": "confirmed"});
                        },
                        child: Text(
                          document.data()['status'] == 'received'
                              ? 'Konfirmasi Penjemputan'
                              : 'Dikonfirmasi',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
