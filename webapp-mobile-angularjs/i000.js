// 页面逻辑定制在这里，布局在 i.html 和 i.css 
iweb.controller('i000', function($scope) {
	
  // 【2】 按键按下 是用户输入，调用这里定义的 input 函数，工具箱那边登录后可>以观察到
  // 通常这里会收集一些数据，一起发送到服务器。比如一个选日期的界面，这里就应>该有用选择的日期
  $scope.input = function(event) {
  	apiconn.send_obj({
		// 典型的请求都有这两个字段，
		"obj": "associate",
		"act": "mock",
		"to_login_name": TOOLBOX_ACCOUNT,
		"data": {
			"obj":"test",
			"act":"input1", // 区分不同的输入
			// 通常还有采集到的用户在界面输入的其他数据，一起发送好了
			// data 可以是复杂的哈希数组
			"data":$scope.inputMsg
		}
	});

	// 典型的接口请求，构造一个请求包 调用 send_obj 就可以了
	// 就是这个send可能会被SDK拒绝。接收后，如果服务端超时，
	// 会在15秒内给出响应： uerr: ERR_CONNECTION_EXCEPTION
  };

  $scope.output = "等待服务端数据";
  
  $scope.$on("RESPONSE_RECEIVED_HANDLER", function(event, jo) {

	// 约定是响应的JSON里面如果有 uerr 错误码字段，说明用户
	// 要处理。 ustr 是文本字符串的错误说明
	// 另外是 derr 是说明程序错误，不是用户导致的。用户不用作处理。
	
    // 【3】 工具箱那里按键 "send input" 后，会发送数据到本APP。这个是模拟服务器 “输出”
    // 如果APP 要响应服务器的输出，像请求响应，或服务器的推送，就可以在>这里定义要做的处理
    // 工具箱那里按键"send input" 这个： 
    // {"obj":"associate","act":"mock","to_login_name":"IWEB_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}

	if (jo.obj == "test" && jo.act == "output1") {
		// 服务端的数据来了，呈现
		$scope.output = jo.data;
	}
	if (jo.obj == "associate" && jo.act == "mock") {
		$scope.output = "mock resp "+Date.now();
	}
	if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {
		$scope.message = "帐号："+IWEB_ACCOUNT+" 这边已经自动登录。请在工具箱那边登录："+TOOLBOX_ACCOUNT
	}
  });
});
