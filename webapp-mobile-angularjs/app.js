// Based on AngularJS 1.4.2


// 【初始化和登录 执行顺序 A--G】

// 【1】开发者应该有自己两个帐号，一个在工具箱登录，一个是本程序APP登录用的。
// IWEB_ACCOUNT 是本程序APP用的，TOOLBOX_ACCOUNT 是工具箱登录用的。工具箱
// 登录后可以观察APP发送的数据，也可以给APP发送数据
// APP 发送的数据叫 “输入” 输入可以是用户输入，界面操作，按键按下等

var IWEB_ACCOUNT    = "test2"; // APP启动时候登录
var TOOLBOX_ACCOUNT = "test1"; // 工具箱配合的账号





var iweb = angular.module('iweb', ['ngRoute']);

// AngularJS 路由。所有UI页的配置，每个都有UI布局页面 html文件 和对应的控制器代码
iweb.config(['$routeProvider',
  	function($routeProvider) {

		// 我们的风格是进入页面在这里创建 controller 所以具体的 html 里面不用声明 ng-controller 了
    		$routeProvider.
      		when('/i000', {
    			templateUrl: 'i000.html',
    			controller: 'i000'
      		}).
      		when('/i072', {
    			templateUrl: 'i072.html',
    			controller: 'i072'
      		}).
      		when('/main', {
    			templateUrl: 'main.html',
    			controller: 'main'
      		}).
      		otherwise({
    			redirectTo: '/main'
      		});
}]);

// save a handle to the $rootScope obj
var rootScope;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 跳转到某个控制器，一个UI页就是一个控制器
function goto_view(v) {
  	var baseUrl = window.location.href;
	baseUrl = (baseUrl.indexOf('#') > 0 ? baseUrl.substr(0, baseUrl.indexOf('#')) : baseUrl);
	window.location.href = baseUrl + "#/" + v;
}

function logout() {
	sessionStorage.setItem("login_name", "");
	sessionStorage.setItem("login_passwd", "");
	apiconn.lgout();
}

// 全局SDK用的变量 【初始化和登录 A】
var apiconn = new APIConnection();

// client_info 可选，每次请求，会自动带上，发送给服务端
apiconn.client_info.clienttype = "web";

// 定义这样一个监听器，用来处理SDK 来的说与服务端连接状态改变了的通知 【初始化和登录 B】
apiconn.state_changed_handler = function() {

	rootScope.$apply(function() {
	
		console.log("state: "+apiconn.from_state+" => "+apiconn.conn_state);
	
		// 这时候成功进入登录状态了。没登录时候只是访客状态。【初始化和登录 G】
		if (apiconn.conn_state == "IN_SESSION") {
	
			sessionStorage.setItem("login_name", apiconn.login_name);
			sessionStorage.setItem("login_passwd", apiconn.login_passwd);
				
		// 连接状态，表明SDK和服务端已经成功连上，获得了 server_info
		// 客户端可以允许用户输入密码（或从客户端保存密码）进行登录了 【初始化和登录 E】
		} else if (apiconn.conn_state == "LOGIN_SCREEN_ENABLED") {
	
			// auto re login after page refresh
			// 处理网页刷新自动登录的机制
			/*
			if (apiconn.login_name == "" && apiconn.credential_data == null) {
	
				var login_name = sessionStorage.getItem("login_name");
	            var login_passwd = sessionStorage.getItem("login_passwd");
			
				var cred = sessionStorage.getItem("credential_data");
				var cred_obj = null;
				if (cred !== "") cred_obj = JSON.parse(cred);
	
				if (login_name != "" && login_name != null) {
					apiconn.login(login_name, login_passwd);
	
				} else if (cred_obj != null) {
					apiconn.loginx(cred_obj);
					
				} else {
				}
			}*/
			
		}
		
		rootScope.$broadcast("STATE_CHANGED_HANDLER", {});
	});
};


// SDK 说服务端有数据过来了，这可以是请求的响应，或推送 【初始化和登录 C】
apiconn.response_received_handler = function(jo) {

	rootScope.$apply(function() {
	
		if (jo.obj == "person" && jo.act == "logout") {
			goto_view("main");
			return;
		}
		
		// 通用报错机制
		if (jo.ustr != null && jo.ustr != "") alert(jo.ustr);

		// 通过这个机制，分发到所有控制器，感兴趣的控制器可以这样监听
		// $scope.$on("RESPONSE_RECEIVED_HANDLER", function(event, jo) {}
		if (jo.obj == "sdk" && jo.act == "switchreq") {
			return goto_view(jo.ixxx);
		}
		
		rootScope.$broadcast("RESPONSE_RECEIVED_HANDLER", jo);
	});
};


// 【初始化和登录 D】
apiconn.wsUri = "ws://112.124.70.60:51727/demo";

iweb.run(['$rootScope', function ($rootScope) {
	rootScope = $rootScope;
	apiconn.connect();
}]);


