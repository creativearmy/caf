import 'package:flutter/material.dart';
import 'package:creativearmy/creativearmy.dart';
import 'package:toast/toast.dart';

import 'home.dart';

class AccountPage extends StatefulWidget {
  @override
  AccountPageState createState() {
    return new AccountPageState();
  }
}

class AccountPageState extends State<AccountPage> with APIConnectionListener {

  // returned data from api call test:echo
  String echo = null;

  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  @override // APIConnectionListener
  void response_received(JSONObject jo) {

    if (jo.s("obj") == "person" && jo.s("act") == "login") {
      if (jo.s("ustr") != "")
        return Toast.show(jo.s("ustr"), context, duration: Toast.LENGTH_SHORT, gravity:  Toast.TOP);

      APIConnection.inst.user_joread().then((JSONObject jo){
        jo.sp("login_name", loginController.text);
        APIConnection.inst.user_jowrite(jo);
      });

      APIConnection.inst.clog("AccountPageState goto HomePage");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
    if (jo.s("obj") == "test" && jo.s("act") == "echo") {
      echo = jo.s("echo");
      setState((){});
    }
  }

  @override
  void initState() {
    super.initState();
    APIConnection.inst.response_received_handlers_subscribe(this);
  }

  @override
  void dispose() {
    APIConnection.inst.response_received_handlers_unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    var width = MediaQuery.of(context).size.width;

    APIConnection.inst.user_joread().then((JSONObject jo){
      loginController.text = jo.s("login_name");
    });

    final loginField = TextField(
      obscureText: false,
      controller: loginController,
      decoration: InputDecoration(
          hintText: "Login Name",
          hintStyle: TextStyle(fontWeight: FontWeight.w300, color: Colors.red)
      ),
    );

    final passwordField = TextField(
      obscureText: true,
      controller: passwordController,
      decoration: InputDecoration(
          hintText: "Password",
          hintStyle: TextStyle(fontWeight: FontWeight.w300, color: Colors.red)
      ),
    );

    final loginButon = new RaisedButton(
      onPressed: () {
        APIConnection.inst.login(loginController.text, passwordController.text);
      },
      color: Colors.white,
      child: new Container(
        width: 230.0,
        height: 30.0,
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
    );

    return new Scaffold(
        appBar: new AppBar(
        title: new Text('CAF Flutter Demo Login'),
      ),

      body: new Center(
        child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text(
                'Not Logged In:',
                style: new TextStyle(
                  fontSize: 18.0,
                ),
              ),
              new Text(
                (echo==null?"no data from server yet":"server return: "+echo),
                style: new TextStyle(fontSize: 24.0),
              ),

              new RaisedButton(
                onPressed: () {
                  JSONObject jo = JSONObject.jo();
                  jo << {"obj":"test","act":"echo","data":APIConnection.inst.getUnixTime()};
                  APIConnection.inst.send_obj(jo);
                },
                color: Colors.white,
                child: new Container(
                  width: 230.0,
                  height: 30.0,
                  alignment: Alignment.center,
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Text(
                        'Test Echo',
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15.0),
              loginField,
              SizedBox(height: 15.0),
              passwordField,
              SizedBox(height: 15.0),
              loginButon,
              SizedBox(height: 15.0),
            ],
        ),
      ),
    );
  }
}
