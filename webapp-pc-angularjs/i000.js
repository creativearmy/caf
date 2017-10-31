
iweb.controller('i000', function($scope) {
	
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
  
  $scope.$on("RESPONSE_RECEIVED_HANDLER", function(event, jo) {

    // {"obj":"associate","act":"mock","to_login_name":"IWEB_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}

	if (jo.obj == "test" && jo.act == "output1") {

		$scope.output = jo.data;
	}
	if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {

		$scope.message = "account:"+IWEB_ACCOUNT+" log in successfully, now on Project Toolbox, log in with:"+TOOLBOX_ACCOUNT
	}
  });
});
