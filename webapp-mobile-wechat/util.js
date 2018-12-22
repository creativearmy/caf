
// import util from "utils/util.js"
// util.cb["a/b"] = function () {};
// util.apiconn.send_obj({"obj":"a","act":"b",...});

import apimod from "APIConnectionWX.min.js";

var apiconn = new apimod.APIConnection();
apiconn.wsUri = "wss://wahalife.cn/waha_ga";

apiconn.state_changed_handler = function() {
};

// callbacks to handle data reponse from server
var cb = {};

apiconn.response_received_handler = function(jo) {
  if (jo.obj == "server" && jo.act == "info") {
    apiconn.send_obj({
	  obj: "loginInfo",
	  act: "get",
	  code: apiconn.user_data.wxcode
	});
  } else if (jo.obj == "loginInfo" && jo.act == "get") {
    apiconn.loginx({
	  access_token: jo.response.session_key,
	  ctype: "user",
	  openid: jo.response.openid
	});
  } else if (cb[jo.obj + "/" + jo.act]) {
    cb[jo.obj + "/" + jo.act](jo);
  } else {
  	console.log("handler missing: "+jo.obj + "/" + jo.act);
  }
};

function login_at_launch() {
  wx.login({
    success: res => {
	  apiconn.user_data.wxcode = res.code;
	  apiconn.connect();
	}
  });
}

module.exports = {
  login_at_launch: login_at_launch,
  cb: cb,
  apiconn: apiconn
};

