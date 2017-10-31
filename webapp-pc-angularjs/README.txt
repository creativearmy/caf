
 =============================================================================
 =                                                                           =
 =                            Webapp for PC, in AngularJS                    =
 =                                                                           =
 =============================================================================

-) We use AngularJS 1.4.2 in our app. To transition to another page, use goto_view


-) Pages and associated css/html layout code files shall be named with "ixxx"
   where "xxx" uniquely identify a page, ixxx.js, ixxx.css, and controller ID ixxx


-) Make sure app.js is properly configured for your project. For demo, we use
 
    #define WSURL @"ws://112.124.70.60:51727/demo"


-) Code each page layout in their respective ixxx.html and ixxx.css


-) Each page can be tested individually with our Project Toolbox


-) To create a new page, use i000.* as templage


-) Global CSS definitions go to global.css


-) Controller html starts with <div class="ixxx">


-) For each new page, add an entry for page transition in app.js

    iweb.config(['$routeProvider',
      
    function($routeProvider) {

        $routeProvider.
        when('/ixxx', {
             templateUrl: 'ixxx.html',
             controller: 'ixxx'
        }).


-) ixxx.js starts like this:

    iweb.controller('ixxx', function($scope) {


-) For each new page, add an entry in index.html

    <link href="ixxx.css" rel="stylesheet">
    <script src="ixxx.js"></script>


-) This command on project toolbox will cause any app where test2 logs in
   to transition to page identified with i072

     Switch test2 72

   This feature can be used to test each page individually, before they
   are hooked with real server API


-) app.js defines two login names to pair this app with project toolbox
   where another account logs into.


-) Demo project toolbox:

   http://www.hehuo168.com/dev/c9sALD5OrfBMbzUYda4Yaw36QQU.html


