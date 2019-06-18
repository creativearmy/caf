import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

import 'package:creativearmy/creativearmy.dart';

class ChatPage extends StatefulWidget {
  @override
  ChatPageState createState() {
    return new ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> with APIConnectionListener {

  // chat - two person chat; group - group chat
  // for demo, we support group chat only
  String mode = "group";

  String group_id; // header_id

  // we reverse the AnimatedList view, to be able to jumpTo 0,
  // entries are reversed after they are reveived from the server
  JSONArray messages;
  
  final TextEditingController text_editing_controller = new TextEditingController();
  // key for animation purpose
  final GlobalKey<AnimatedListState> list_key = GlobalKey<AnimatedListState>();
  final ScrollController scroll_controller = ScrollController();

  bool is_composing_message = false;

  @override // APIConnectionListener
  void response_received(JSONObject jo) {

    if (jo.s("obj") == "push" && jo.s("act") == "message_group") {

      // place the new message at the front
      messages.data.insert(0, jo.data);

      //setState((){}); notify AnimiatedList through listKey instead of setState
      list_key.currentState.insertItem(0);

      scroll_controller.jumpTo(0);
    }

    if (jo.s("obj") == "group" && jo.s("act") == "join") {

      group_id = jo.s("header_id");

      // get the first block
      APIConnection.inst.send_obj(JSONObject.jo()<<
          {"obj":"message","act":"group_get","header_id":group_id});
    }

    if (jo.s("obj") == "message" && jo.s("act") == "group_get") {

      // get two blocks of messages, because first block might only
      // have one message entry; we get two blocks to be sure
      bool first = (messages == null);

      // reverse the entries after receiving it
      List<dynamic> m = jo.o("block").a("entries").data.reversed.toList();

      if (first) messages = (JSONArray.ja() << m);
      else messages = (JSONArray.ja() << (m + messages.data));

      // get a second block
      if (first && jo.s("next_id") != "") {
        APIConnection.inst.send_obj(JSONObject.jo()<<
            {"obj":"message","act":"group_get","header_id":jo.s("next_id")});
      }

      setState((){});
    }

  }

  @override
  void initState() {
    super.initState();
    APIConnection.inst.response_received_handlers_subscribe(this);
    APIConnection.inst.send_obj(JSONObject.jo()<<
        {"obj":"group","act":"join"});
  }

  @override
  void dispose() {
    APIConnection.inst.response_received_handlers_unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (messages == null) return new Container();

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("CAF Chat Demo"),
          elevation:
          Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.exit_to_app), onPressed: (){})
          ],
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: new AnimatedList(

                  controller: scroll_controller, // scroll controller

                  key: list_key, // for animation, keep all the global states
                  reverse: true, // reverse view, jumpTo 0 goes to the "bottom"

                  padding: const EdgeInsets.all(8.0),
                  initialItemCount: messages.data.length,
                  itemBuilder: (context, index, animation) {
                    return new ChatMessageListItem(
                      message: messages.o(index),
                      animation: animation,
                    );
                  },
                ),
              ),
              new Divider(height: 1.0),
              new Container(
                decoration:
                new BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(context),
              ),
              new Builder(builder: (BuildContext context) {
                return new Container(width: 0.0, height: 0.0);
              })
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
              border: new Border(
                  top: new BorderSide(
                    color: Colors.grey[200],
                  )))
              : null,
        ));
  }

  CupertinoButton getIOSSendButton() {
    return new CupertinoButton(
      child: new Text("Send"),
      onPressed: is_composing_message
          ? () => _textMessageSubmitted(text_editing_controller.text)
          : null,
    );
  }

  IconButton getDefaultSendButton() {
    return new IconButton(
      icon: new Icon(Icons.send),
      onPressed: is_composing_message
          ? () => _textMessageSubmitted(text_editing_controller.text)
          : null,
    );
  }

  Widget _buildTextComposer(BuildContext context) {
    return new IconTheme(
        data: new IconThemeData(
          color: is_composing_message
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,
        ),
        child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(
            children: <Widget>[

              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: new IconButton(
                    icon: new Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).accentColor,
                    ),

                    onPressed: () async {

                      File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery); //ImageSource.camera
                      List<int> bytes = await imageFile.readAsBytes();

                      var request = new http.MultipartRequest("POST",
                          Uri.parse(APIConnection.inst.server_info.s("upload_to")));

                      request.fields['proj'] = APIConnection.inst.server_info.s("proj");

                      // filename is required!
                      request.files.add(new http.MultipartFile.fromBytes('local_file', bytes, filename: basename(imageFile.path)));

                      // StreamedResponse
                      request.send().then((response) {

                        if (response.statusCode == 200) {

                          // ByteStream listen for response
                          response.stream.transform(utf8.decoder).listen((value) {

                            JSONObject jo = JSONObject.parse(value);

                            print("chat.dart upload return: $value");

                            // send chat image
                            _sendMessageImage(jo.s("fid"), jo.s("thumb"));
                          });

                        } else {
                          print("chat.dart upload error: " + response.statusCode.toString());
                        }

                      });
                    }),
              ),

              new Flexible(
                child: new TextField(
                  controller: text_editing_controller,
                  onChanged: (String messageText) {
                    setState(() {
                      is_composing_message = messageText.length > 0;
                    });
                  },
                  onSubmitted: _textMessageSubmitted,
                  decoration:
                  new InputDecoration.collapsed(hintText: "Message text"),
                ),
              ),

              new Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? getIOSSendButton()
                    : getDefaultSendButton(),
              ),
            ],
          ),
        ));
  }

  Future<Null> _textMessageSubmitted(String text) async {
    text_editing_controller.clear();

    setState(() {
      is_composing_message = false;
    });

    _sendMessageText(text);
  }

  void _sendMessageText(String messageText) {
    if (messageText != null) {
      APIConnection.inst.send_obj(JSONObject.jo() << {
        'obj': "message",
        'act': "group_send",
        'header_id': group_id,
        'mtype': "text",
        'content': messageText,
      });
    }
  }

  void _sendMessageImage(String imageFID, String imageThumb) {

    if (imageFID != null && imageThumb != null) {
      APIConnection.inst.send_obj(JSONObject.jo() << {
        'obj': "message",
        'act': "group_send",
        'header_id': group_id,
        'mtype': "image",
        'content': {
          'fid': imageFID,
          'thumb': imageThumb,
        },
      });
    }
  }

}


////////////////////////////////////////////////////////////////////////////////

class ChatMessageListItem extends StatelessWidget {

  final JSONObject message;
  final Animation animation;

  ChatMessageListItem({this.message, this.animation});

  @override
  Widget build(BuildContext context) {
    return new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          children: APIConnection.inst.user_info.s("_id") == message.s("from_id")
              ? getSentMessageLayout()
              : getReceivedMessageLayout(),
        ),
    );
  }

  List<Widget> getSentMessageLayout() {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            new Text(message.s("from_name"),
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: message.s("mtype") == "image" ?
                new Image.network(
                  APIConnection.inst.server_info.s("download_path")
                      + message.o("content").s("thumb"),
                  width: 250.0,
                ) : new Text(message.s("content")),
            ),
          ],
        ),
      ),
      new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: new CircleAvatar(
                backgroundImage:
                new NetworkImage(
                    APIConnection.inst.server_info.s("download_path")
                    + message.s("from_avatar")
                ),
              )),
        ],
      ),
    ];
  }

  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: new CircleAvatar(
                backgroundImage:
                new NetworkImage(
                    APIConnection.inst.server_info.s("download_path")
                        + message.s("from_avatar")
                ),
              )),
        ],
      ),
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text(message.s("from_name"),
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: message.s("mtype") == "image" ?
              new Image.network(
                APIConnection.inst.server_info.s("download_path")
                    + message.o("content").s("thumb"),
                width: 250.0,
              ) : new Text(message.s("content")),
            ),
          ],
        ),
      ),
    ];
  }
}
