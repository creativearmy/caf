
iweb.controller('i072', function($scope) {
	
  $scope.input = function(event) {
  	/*apiconn.send_obj({
		"obj": "associate",
		"act": "mock",
		"to_login_name": TOOLBOX_ACCOUNT,
		"data": {
			"obj":"test",
			"act":"input1", 
			"data":$scope.inputMsg
		}
	});*/

	};
	
	$scope.output = "Wait for server";
	
	$scope.personData = {
	      "name": "Lee",
	      "province": "prov name",
	      "city": "city name"
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
      	/*apiconn.send_obj({
    		"obj": "associate",
    		"act": "mock",
    		"to_login_name": TOOLBOX_ACCOUNT,
    		"data": {
    			"obj":"test",
    			"act":"weixin_pay"
    		}
    	});*/
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


	$scope.uploadProgress = function(evt) {
		if (evt.lengthComputable) {
			var percentComplete = Math.round(evt.loaded * 100 / evt.total);
			document.getElementById('_progressNumber').innerHTML = percentComplete.toString() + '%';
		} else {
			document.getElementById('_progressNumber').innerHTML = 'unable to compute';
		}
		if (percentComplete.toString() == 100) {
			var upDate = new Date;
			$scope.file_time = upDate.getFullYear() + '.' + (upDate.getMonth() + 1) + '.' + upDate.getDate() + ' ' + upDate.getHours() + ':' + upDate.getMinutes(); //
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

		alert("upload succeed");
	}

	$scope.uploadFailed = function(evt) {
		alert("There was an error attempting to upload the file.");
	}

	$scope.uploadCanceled = function(evt) {
		alert("The upload has been canceled by the user or the browser dropped the connection.");
	}


  $scope.$on("RESPONSE_RECEIVED_HANDLER", function(event, jo) {

    // {"obj":"associate","act":"mock","to_login_name":"IWEB_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}

	if (jo.obj == "test" && jo.act == "output1") {

		$scope.output = jo.data;
	}
	if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {
  		$scope.headURL = apiconn.server_info.download_path + apiconn.user_info.headFid;

  		console.log($scope.headURL);

		$scope.message = "account:"+IWEB_ACCOUNT+" log in successfully, now on Project Toolbox, log in with:"+TOOLBOX_ACCOUNT
	}
  });
});
