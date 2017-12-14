
iweb.controller('i001', function ($scope) {

        $scope.action1 = function () {
			alert("Action 1");
            //goto_view('i315');
        };
        $scope.action2 = function () {
			alert("Action 2");
            //goto_view("i303");
        };

        $scope.output = "Wait for server";

        $scope.i001 = {};
        $scope.i001.select = 'XXX'


        $scope.go_href = function (href) {
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "go_href",
                    "data": href
                }
            });*/
        };


        $scope.go_search = function () {
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "go_search",
                    "data": "search"
                }
            });*/
        };


        $scope.go_xiugai = function (index) {
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "go_xiugai",
                    "data": {
                        href: 'i317',
                        index: index
                    }
                }
            });*/
        };
        $scope.go_xiangqing = function (index) {
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "go_xiangqing",
                    "data": {
                        href: 'i317',
                        index: index
                    }
                }
            });*/
        };

        $scope.chaxun = function () {
            var data = $scope.i001.select + '';
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "go_chaxun",
                    "data": data
                }
            });*/
        }
        $scope.shenhei = function () {
            var data = $scope.i001.select + '';
            /*apiconn.send_obj({

                "obj": "associate",
                "act": "mock",
                "to_login_name": TOOLBOX_ACCOUNT,
                "data": {
                    "obj": "test",
                    "act": "shenhei",
                    "data": data
                }
            });*/
        }


        $scope.$on("RESPONSE_RECEIVED_HANDLER", function (event, jo) {


            if (jo.obj == "test" && jo.act == "output1") {

                console.log(jo.data);
                $scope.i001 = jo.data;
                $scope.i001.select = 'XXX'
            }
            if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {

		$scope.message = "account:"+IWEB_ACCOUNT+" log in successfully, now on Project Toolbox, log in with:"+TOOLBOX_ACCOUNT
            }
        });
    }
)
;
