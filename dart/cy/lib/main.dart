import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  var _cfg = {};
  var _client = Dio();
  var _ts = ['36.4', '36.5', '36.6', '36.7', '36.8'];
  var _hs = {'早': '07', '中': '11', '晚': '17'};
  var _toast = FToast();

  @override
  void initState() {
    super.initState();

    _toast.init(context);

    var cookieJar = CookieJar();
    _client.interceptors.add(CookieManager(cookieJar));
  }

  void _report(String nn, String tt) async {
    if (_cfg.isEmpty) {
      var s = await rootBundle.loadString('assets/cfg.json');
      _cfg = jsonDecode(s);
      _client.options.baseUrl = _cfg['base_url'];
    }
    _client.options.headers['Content-Type'] =
        'application/x-www-form-urlencoded';
    var login_res = await _client.post(_cfg['login_path'], data: _cfg[nn]);
    var login_json = jsonDecode(login_res.data);
    print('$login_json');
    var name = login_json['info']['usrName'];
    var report_data = _cfg['report_data'];
    var date = DateTime.now();
    var d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    var h = _hs[tt];
    var m = Random().nextInt(30) + 10;
    report_data['epShiduan'] = tt;
    report_data['epTemperature'] = _ts[Random().nextInt(_ts.length)];
    report_data['epDate'] = '$d $h:$m';
    _client.options.headers['Content-Type'] =
        'application/x-www-form-urlencoded; charset=UTF-8';
    var report_res = await _client.post(_cfg['report_path'], data: report_data);
    var report_json = jsonDecode(report_res.data);
    print('$report_json');
    var code = report_json['code'];

    _toast.showToast(
      child: Container(
        child: Center(
            child: Text(
          '$name $tt ${code.toString()}',
          style: TextStyle(
              color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
        )),
        color: Colors.blue,
        width: 200,
        height: 60,
      ),
      toastDuration: Duration(seconds: 1),
    );
  }

  void _reportShuhan1() {
    _report('han', '早');
  }

  void _reportShuhan2() {
    _report('han', '中');
  }

  void _reportShuhan3() {
    _report('han', '晚');
  }

  void _reportShuya1() {
    _report('ya', '早');
  }

  void _reportShuya2() {
    _report('ya', '中');
  }

  void _reportShuya3() {
    _report('ya', '晚');
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 20, height: 20),
            Row(children: [
              const SizedBox(width: 20, height: 20),
              const Text(
                '李姝涵：',
              ),
              ElevatedButton(
                onPressed: _reportShuhan1,
                child: Text('早'),
              ),
              const SizedBox(width: 20, height: 20),
              ElevatedButton(
                onPressed: _reportShuhan2,
                child: Text('中'),
              ),
              const SizedBox(width: 20, height: 20),
              ElevatedButton(
                onPressed: _reportShuhan3,
                child: Text('晚'),
              ),
            ]),
            const SizedBox(width: 20, height: 20),
            Row(children: [
              const SizedBox(width: 20, height: 20),
              const Text(
                '李姝雅：',
              ),
              ElevatedButton(
                onPressed: _reportShuya1,
                child: Text('早'),
              ),
              const SizedBox(width: 20, height: 20),
              ElevatedButton(
                onPressed: _reportShuya2,
                child: Text('中'),
              ),
              const SizedBox(width: 20, height: 20),
              ElevatedButton(
                onPressed: _reportShuya3,
                child: Text('晚'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
