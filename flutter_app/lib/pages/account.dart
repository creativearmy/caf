import 'package:flutter/material.dart';
import 'package:creativearmy/creativearmy.dart';

import 'home.dart';

class AccountPage extends StatefulWidget {
  @override
  AccountPageState createState() {
    return new AccountPageState();
  }
}

class AccountPageState extends State<AccountPage> with APIConnectionListener {

  @override
  void response_received(JSONObject jo) {
    if (jo.s("obj") == "person" && jo.s("act") == "login") {
      APIConnection.inst.clog("AccountPageState goto HomePage");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    var width = MediaQuery.of(context).size.width;

    // initialize websocket connection
    if (APIConnection.inst.wsUri == "") {
      APIConnection.inst.wsUri = "ws://47.92.169.34:51700/demo";
      APIConnection.inst.response_received_handlers_subscribe(this);
      APIConnection.inst.connect();
      APIConnection.inst.req_server_info();
    }

    return new Container(
      width: width,
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new RaisedButton(
            onPressed: () {
              APIConnection.inst.login("test1","1");
            },
            color: Colors.white,
            child: new Container(
              width: 230.0,
              height: 50.0,
              alignment: Alignment.center,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  new Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
