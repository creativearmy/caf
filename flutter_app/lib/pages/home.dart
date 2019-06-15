import 'package:flutter/material.dart';
import 'package:creativearmy/creativearmy.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> with APIConnectionListener {

  // returned data from api call test:echo
  String echo = null;

  @override
  void response_received(JSONObject jo) {
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

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('CAF Flutter Demo'),
      ),

      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            new Text(
              'Logged In:',
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
                height: 50.0,
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

          ],
        ),
      ),
    );
  }
}
