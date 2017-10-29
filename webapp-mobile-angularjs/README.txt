
			模板工程使用说明

==============================================================================

-）我们使用 Angular JS 1.4.2 前端框架，我们做了封装，goto_view 用来跳转的

-）新的界面控制器和相关类必须用 ixxx 开头，i小写，xxx 是界面编号

-）这个命名规则包括界面用到的资源 ixxx.js，控件ID, 布局 css文件名字等

-）拿到工程后，首先确保 AppDelegate.m 里面的改到项目的服务器地址
 
	#define WSURL @"ws://112.124.70.60:51727/demo"

-）按照项目策划设计，修改登录风格

-）新的界面可以同时添加和开发和测试验收，APP串联也可以同时进行

-）新的界面开发可以拷贝 i000.* 模板开始

-）全局CSS 在 global.css 文件里面

-）每个控制器的 html 要以 <div class="ixxx"> 开始， 这样 css 里面的风格才能保证不会和其他控制器冲突

-）添加新界面后，在这里面添加一条跳转 app.js

	iweb.config(['$routeProvider',
  	
	function($routeProvider) {

		// 我们的风格是进入页面在这里创建 controller 所以具体的 html 里面不用声明 ng-controller 了
    		$routeProvider.
      		when('/ixxx', {
    			templateUrl: 'ixxx.html',
    			controller: 'ixxx'
      		}).

-）添加新界面后，ixxx.js 里面要用 

	iweb.controller('ixxx', function($scope) {

-）添加新界面后，index.html 里面要加

    <link href="ixxx.css" rel="stylesheet">
    <script src="ixxx.js"></script>

-）这样工具箱的 Switch 按键就可以启用了，

	Switch test2 72

   Switch 后面的两个参数是被测试的APP那边的登录名字，和界面编号
   按键后，观察界面编号为 i072 的跳到前面，可以对界面进行单独测试，验收
   具体Switch 使用说明看 文档中心 t305

-) 工具箱要登录的帐号是要看代码里面 TOOLBOX_ACCOUNT 怎么配置的
   APP 是用 TOOLBOX_ACCOUNT 填写到 to_login_name 发送目标的
   工具箱只有登录后，代码里面的向工具箱发送的才可以收到。演示学习工具箱地址

   http://www.madao168.com/dev/qMRUqc7mbpatAeXUWEE6Supkt98.html
   实际开发的过程必须使用项目专有的工具箱



