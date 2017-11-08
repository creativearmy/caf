# Creativearmy App Framework (CAF)


WebSocket web and mobile realtime app framework, with backend coding in Perl.


<br><b>Architecture Overview</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<http://www.hehuo168.com/en/architecture.pdf>

<br><b>Content List</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This repository contains a complete sample app project with server and<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;client HTML5 webapp, native Android/iOS apps and associated Project Toolbox.<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Project contains server and client SDKs in binary form which are not open sourced.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This sample app works as it is. It will connect to our demo server. You can add new APIs<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;or make changes to our existing demo server API logics on its Project Toolbox.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;On Project Toolbox click on "Server APIs" to see a [list of APIs implemented](http://112.124.70.60/manual_demo.html).

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;To have your own app server and start developing your project:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Please have a server (Ubuntu 16.04 preferred) ready, and send us a provision request.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;We will provision your server to work with these client SDKs and our cloud<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;IDE called Project Toolbox. This service is free of charge. After provisioning, be sure to<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;check out our network of talented coders for all your project development and upkeep needs.<br>

<br><b>Project Toolbox</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Each project comes with its own online IDE called Project Toolbox<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Project Toolbox can make API calls, manage database, update server code on the fly,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;review server logs, send mock API return to client apps, look up server APIs and<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;data schema, make changes to volitle and persistent data on client apps,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;and many more... Project Toolbox itself is a webapp connecting to the same server.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<http://www.hehuo168.com/dev/c9sALD5OrfBMbzUYda4Yaw36QQU.html>

<br><b>Messaging API</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Our sample app has implemented two-party simple chat APIs. It is a classic<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;example showing realtime messaging capability. Our Project Toolbox is a webapp<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;client that talks to our server. Now try open [Project Toolbox](http://www.hehuo168.com/dev/c9sALD5OrfBMbzUYda4Yaw36QQU.html) in two browsers,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;and log into them with login name "test1" and "test2", and password "1". After login,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;you will see person id displayed on top of Project Toolbox. On one Project Toolbox<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;where you log in with "test1", send the following JSON api request, and make sure<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;from_id and to_id matches what is displayed on top of the two Project Toolbox.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Observe on the other Project Toolbox to see a push message displayed in the output area.<br>
```
{
    "obj":          "message",
    "act":          "chat_send",
    "from_id":      "o14509039359136660099",
    "to_id":        "o14458500088436288833",
    "mtype":        "text",
    "content":      "Hello, Partner!"
}
```

<br><b>FREE Online Wireframe Tool</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Design your clickable app prototypes right on our [home page](http://www.hehuo168.com/en).

<br><b>Questions? Chat with us</b>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Join our Slack channel. You are invited.](https://join.slack.com/t/creativearmy/shared_invite/enQtMjU1Mjc3MjMzMjk5LWIxN2MyMjI4N2NjNmQyMmM3MzU1MzVhYzFiZTBlYTZjMzkwOTQwNTU1NzJlOTE3NWI5MmI4YTQxZThlNjEzM2U)

<br><b>Creative Army Productions Home Page</b>![alt text](http://www.hehuo168.com/hehuo20.png "Creative Army Productions")

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<http://www.hehuo168.com/en>



