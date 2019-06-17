import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:creativearmy/creativearmy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  @override
  ChatPageState createState() {
    return new ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> with APIConnectionListener {

  final TextEditingController _textEditingController = new TextEditingController();
  bool _isComposingMessage = false;

  // chat - two person chat; group - group chat
  // for demo, we support group chat only
  String mode = "group";
  String group_id; // header_id
  JSONArray messages;

  @override // APIConnectionListener
  void response_received(JSONObject jo) {

    if (jo.s("obj") == "push" && jo.s("act") == "message_group") {
      messages.data.insert(0, jo.data);
      setState((){});
    }

    if (jo.s("obj") == "group" && jo.s("act") == "join") {

      group_id = jo.s("header_id");

      // get the first block
      APIConnection.inst.send_obj(JSONObject.jo()<<
          {"obj":"message","act":"group_get","header_id":group_id});
    }

    if (jo.s("obj") == "message" && jo.s("act") == "group_get") {

      // get two blocks of messages, because first block might only
      // have one message entry
      bool first = (messages == null);

      if (first) messages = jo.o("block").a("entries");
      else messages = JSONArray.ja() << (jo.o("block").a("entries").data + messages.data);

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

  // key for animation purpose
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

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
                  key: listKey,
                  padding: const EdgeInsets.all(8.0),
                  reverse: true,
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
                child: _buildTextComposer(),
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
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  IconButton getDefaultSendButton() {
    return new IconButton(
      icon: new Icon(Icons.send),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        data: new IconThemeData(
          color: _isComposingMessage
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

                      request.files.add(new http.MultipartFile.fromBytes('local_file', bytes));

                      // StreamedResponse
                      request.send().then((response) {

                        if (response.statusCode == 200) {

                          // ByteStream
                          response.stream.bytesToString().then((String s) {

                            JSONObject jo = JSONObject.parse(s);

                            print("chat.dart upload return: $s");

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
                  controller: _textEditingController,
                  onChanged: (String messageText) {
                    setState(() {
                      _isComposingMessage = messageText.length > 0;
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
    _textEditingController.clear();

    setState(() {
      _isComposingMessage = false;
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
                    + message.s("content"),
                width: 250.0,
              ) : new Text(message.s("content")),
            ),
          ],
        ),
      ),
    ];
  }
}
