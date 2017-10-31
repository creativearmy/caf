
 =============================================================================
 =                                                                           =
 =                               iOS, Objective-C                            =
 =                                                                           =
 =============================================================================

-) Pair app with Project Toolbox with TOOLBOX_ACCOUNT and IXCODE_ACCOUNT
   in AppDelegate.h Login to to Project Toolbox with TOOLBOX_ACCOUNT


-) To show chat feature, configure the chat person ID (pid) accordingly.
   Different modes of chat are supported: Personal and Topic (Group) 


-) Each page shall name ViewController and related classes with "ixxx" prefix,
   where xxx uniquely identify a page


-) The same naming conventions apply to resource, control ID, layout xib etc.


-) Make sure AppDelegate.m has the correct server string
 
     #define WSURL @"ws://112.124.70.60:51727/demo"


-) modify bundle name and app ID 


-) Code the layout for each page, individually. They can be tested individually
   as well, through the Switch command on Project Toolbox


-) Use i000ViewController as an template


-) For each new page, add an entry for page transition in

    AppDelegate.m
        
        -(void)switchViewController:(NSString*)ixxx


-) This command on project toolbox will cause any app where test2 logs in
   to transition to page identified with i072

     Switch test2 72

   This feature can be used to test each page individually, before they
   are hooked with real server API


-) app.js defines two login names to pair this app with project toolbox
   where another account logs into.


-) Demo project toolbox:

   http://www.hehuo168.com/dev/c9sALD5OrfBMbzUYda4Yaw36QQU.html


