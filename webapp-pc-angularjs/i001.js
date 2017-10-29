// 页面逻辑定制在这里，布局在 i.html 和 i.css 
iweb.controller('i001', function ($scope) {

        // 【2】 按键按下 是用户输入，调用这里定义的 input 函数，工具箱那边登录后可>以观察到
        // 通常这里会收集一些数据，一起发送到服务器。比如一个选日期的界面，这里就应>该有用选择的日期
        $scope.add = function () {
            goto_view('i315');
        };
        $scope.guanli = function () {
            goto_view("i303");
        };

        $scope.output = "等待服务端数据";

        $scope.i001 = {};
        $scope.i001.select = 'XXX'


        $scope.go_href = function (href) {
            /*apiconn.send_obj({
                // 典型的请求都有这两个字段，
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
                // 典型的请求都有这两个字段，
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
                // 典型的请求都有这两个字段，
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
                // 典型的请求都有这两个字段，
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
                // 典型的请求都有这两个字段，
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
                // 典型的请求都有这两个字段，
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

            // 约定是响应的JSON里面如果有 uerr 错误码字段，说明用户
            // 要处理。 ustr 是文本字符串的错误说明
            // 另外是 derr 是说明程序错误，不是用户导致的。用户不用作处理。

            // 【3】 工具箱那里按键 "send input" 后，会发送数据到本APP。这个是模拟服务器 “输出”
            // 如果APP 要响应服务器的输出，像请求响应，或服务器的推送，就可以在>这里定义要做的处理

            if (jo.obj == "test" && jo.act == "output1") {
                // 服务端的数据来了，呈现
                console.log(jo.data);
                $scope.i001 = jo.data;
                $scope.i001.select = 'XXX'
            }
            if (jo.obj == "person" && jo.act == "login" && !jo.ustr) {

                $scope.message = "帐号：" + IWEB_ACCOUNT + " 这边已经自动登录。请在工具箱那边登录：" + TOOLBOX_ACCOUNT
            }
        });
    }
)
;
