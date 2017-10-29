// 页面逻辑定制在这里，布局在 i.html 和 i.css 
iweb.controller('i072', function($scope) {
	
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
	
	$scope.personData = {
	      "name": "小李",
	      "province": "省份名字",
	      "city": "城市名字"
	};

	$scope.editImgChanged = function() {
		var file = document.getElementById("editImg").files[0];
		$scope.uploadFile('local_file', file, 200);
	};
	$scope.updataImg = function() {
		document.getElementById("editImg").click();
	};

	// https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_1
	$scope.weixin_pay = function() {
      	apiconn.send_obj({
    		// 典型的请求都有这两个字段，
    		"obj": "associate",
    		"act": "mock",
    		"to_login_name": TOOLBOX_ACCOUNT,
    		"data": {
    			"obj":"test",
    			"act":"weixin_pay"
    		}
    	});
		console.log("to pay weixin 0.01");
	};

	$scope.uploadFile = function(src, data, sizes) {
		var fd = new FormData();
		if (src == 'data_url')
			fd.append("data_url", base64_img);
		else
			fd.append("local_file", data);

		fd.append("proj", apiconn.server_info.proj);
		if (sizes != null) {
			$scope.request_resize = sizes;
			fd.append("sizes", sizes);
		}

		var xhr = new XMLHttpRequest();
		xhr.upload.addEventListener("progress", $scope.uploadProgress, false);
		xhr.addEventListener("load", $scope.uploadComplete, false);
		xhr.addEventListener("error", $scope.uploadFailed, false);
		xhr.addEventListener("abort", $scope.uploadCanceled, false);
		xhr.open("POST", apiconn.server_info.upload_to);
		xhr.send(fd);
	}

	//进度条
	$scope.uploadProgress = function(evt) {
		if (evt.lengthComputable) {
			var percentComplete = Math.round(evt.loaded * 100 / evt.total);
			document.getElementById('_progressNumber').innerHTML = percentComplete.toString() + '%';
		} else {
			document.getElementById('_progressNumber').innerHTML = 'unable to compute';
		}
		if (percentComplete.toString() == 100) {
			var upDate = new Date;
			$scope.file_time = upDate.getFullYear() + '.' + (upDate.getMonth() + 1) + '.' + upDate.getDate() + ' ' + upDate.getHours() + ':' + upDate.getMinutes(); //拼写出的日期2015-3-27
			document.getElementById("updatafile").style.display = "block";
			if ($scope.file_name.length > 30) {
				$("#fileName").html($scope.file_name.substring(0, 17) + "..." + $scope.file_name.substring($scope.file_name.length - 8, $scope.file_name.length) + $scope.file_type);
			} else {
				$("#fileName").html($scope.file_name + $scope.file_type);
			}
			$("#filetime").html($scope.file_time);


		}
	}

	$scope.uploadComplete = function(evt) {
	
		var jo = JSON.parse(evt.target.responseText);

		if ($scope.request_resize != null) {
			// "fid_200":"f111

			$scope.request_resize = null;
		}

		// check the image is ready, and count down 10
		var img = new Image();
		var count = 10;

		img.onload = function() {
			$scope.product_image = jo.fid;
			$("#product_img").attr("src", apiconn.server_info.download_path + jo.fid + "&rn=" + Math.random());
			$("#edit_img").attr("src", apiconn.server_info.download_path + jo.fid + "&rn=" + Math.random());
			$scope.headURL = apiconn.server_info.download_path + jo.fid;
		};

		img.onerror = function() {
			// wait a little bit for the server to catch up
			if (count > 0) {
				count--;
				img.src = apiconn.server_info.download_path + jo.fid + "&rn=" + Math.random();
			}
		};
		img.src = apiconn.server_info.download_path + jo.fid;

		$scope.product_image = jo.fid;
		$("#product_img").attr("src", apiconn.server_info.download_path + jo.fid);
		$("#edit_img").attr("src", apiconn.server_info.download_path + jo.fid);
		$scope.headURL = apiconn.server_info.download_path + jo.fid;

		alert("上传成功！");
	}

	$scope.uploadFailed = function(evt) {
		alert("There was an error attempting to upload the file.");
	}

	$scope.uploadCanceled = function(evt) {
		alert("The upload has been canceled by the user or the browser dropped the connection.");
	}


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
	if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {
  		$scope.headURL = apiconn.server_info.download_path + apiconn.user_info.headFid;

  		console.log($scope.headURL);

		$scope.message = "帐号："+IWEB_ACCOUNT+" 这边已经自动登录。请在工具箱那边登录："+TOOLBOX_ACCOUNT
	}
  });
});
