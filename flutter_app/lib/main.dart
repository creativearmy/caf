import 'package:flutter/material.dart';
import 'package:creativearmy/creativearmy.dart';
import 'pages/account.dart';
import 'pages/home.dart';
import 'pages/chat.dart';

void main() => runApp(AppRootWidget());

class AppRootWidget extends StatefulWidget {
  @override
  AppRootWidgetState createState() => new AppRootWidgetState();
}

class AppRootWidgetState extends State<AppRootWidget> with APIConnectionListener {

  ThemeData get _themeData => new ThemeData(
    primaryColor: Colors.cyan,
    accentColor: Colors.indigo,
    scaffoldBackgroundColor: Colors.grey[300],
  );

  @override // APIConnectionListener
  void response_received(JSONObject jo) {
    if (jo.s("ustr") != "") {
      // global error notification
    }
  }

  @override // APIConnectionListener
  void state_changed() {
  }

  @override
  void initState() {
    // initialize websocket connection
    if (APIConnection.inst.wsUri == "") {
      APIConnection.inst.wsUri = "ws://47.92.169.34:51700/demo";
      APIConnection.inst.response_received_handlers_subscribe(this);
      APIConnection.inst.state_changed_handlers_subscribe(this);
      APIConnection.inst.connect();
      APIConnection.inst.req_server_info();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Inherited',
      debugShowCheckedModeBanner: false,
      theme: _themeData,
      routes: {
        '/': (BuildContext context) => new AccountPage(),
        '/chat': (BuildContext context) => new ChatPage(),
        '/home': (BuildContext context) => new HomePage(),
        '/account': (BuildContext context) => new AccountPage(),
      },
    );
  }
}
