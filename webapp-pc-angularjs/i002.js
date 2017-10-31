/**
 * Created by sangcixiang on 16/8/20.
 */
iweb.controller('i002', function($scope) {

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

    $scope.user = {
        "name":"Tom",
        "id":13760423729,
        "oldPwd":'',
        "newPwd":'',
        "notPwd":''
    }

    $scope.enter = function(user){
        if(user.newPwd.length==0){
            alert("enter password")
            return
        }
        if(user.newPwd != user.notPwd){
            alert("password does not match")
            return
        }
        if(user.newPwd.length<6){
            alert("password is less than 6 digits")
            return
        }
        returnValue = confirm("Save?");
        if(returnValue){
            apiconn.send_obj({

                "obj": "admin",
                "act": "staff_update",
                "to_login_name": TOOLBOX_ACCOUNT,
                "phone":user.mobile,
                "display_name":user.name,
                "login_passwd_old":user.oldPwd,
                "login_passwd_new":user.newPwd
            });
        }
    }
    $scope.cancel = function(){
        goto_view("i303");
    }
    $scope.output = "wait for server";

    $scope.$on("RESPONSE_RECEIVED_HANDLER", function(event, jo) {

        // {"obj":"associate","act":"mock","to_login_name":"IWEB_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}

        if (jo.obj == "test" && jo.act == "output1") {

            $scope.output = jo.data;
        }
        if (jo.obj == "admin" && jo.act == "staff_update") {//
            alert(jo.start);
        }
        if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {

		$scope.message = "account:"+IWEB_ACCOUNT+" log in successfully, now on Project Toolbox, log in with:"+TOOLBOX_ACCOUNT
        }
    });
});
