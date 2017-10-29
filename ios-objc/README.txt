

			模板工程使用说明

==============================================================================

-) 选定一对登录帐号，一个用于工具箱（TOOLBOX_ACCOUNT），一个用于APP（IXCODE_ACCOUNT），
   这个要修改 AppDelegate.h 里面的 IXCODE_ACCOUNT TOOLBOX_ACCOUNT 变量
   如果要用聊天，演示提供私聊，AppDelegate.m 里面的对方（工具箱登录的PID）要改

-）新的界面ViewController 和相关类必须用 ixxx 开头，i小写，xxx 是界面编号

-）这个命名规则包括界面用到的资源，控件ID, 布局 xib文件名字等

-）拿到工程后，首先确保 AppDelegate.m 里面的改到项目的服务器地址
 
	#define WSURL @"ws://112.124.70.60:51727/demo"

-）修改 bundle 名字和 ID 

-）按照项目策划设计，修改登录风格

-）新的界面可以同时添加和开发和测试验收，串联也可以同时进行

-）新的界面可以 i000ViewController 模板

-）添加新界面后，在这里面添加一条跳转

	AppDelegate.m
		
		-(void)switchViewController:(NSString*)ixxx


-）这样工具箱的 Switch 按键就可以启用了，

	Switch test2 72

   Switch 后面的两个参数是被测试的APP那边的登录名字，和界面编号
   按键后，观察界面编号为 i072 的跳到前面，可以对界面进行单独测试，验收
   具体Switch 使用说明看 文档中心 t305

-) 工具箱要登录的帐号是要看代码里面 TOOLBOX_ACCOUNT 怎么配置的
   APP 是用 TOOLBOX_ACCOUNT 填写到 to_login_name 发送目标的
   工具箱只有登录后，代码里面的向工具箱发送的才可以收到。演示学习工具箱地址

   http://www.hehuo168.com/dev/qMRUqc7mbpatAeXUWEE6Supkt98.html
   实际开发的过程必须使用项目专有的工具箱

