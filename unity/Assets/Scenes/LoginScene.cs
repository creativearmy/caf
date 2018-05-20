using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using APIConnection;

public class LoginScene : MonoBehaviour {

    public InputField login_name;
    public InputField login_passwd;
    public Text system_message;

	// Use this for initializatio n
	void Start () {
        APIConn.Inst.wsUri = "ws://112.124.70.60:51727/demo";
        APIConn.Inst.logger = Debug.Log;
        APIConn.Inst.response_received_handlers += this.response_hander;
        APIConn.Inst.state_changed_handlers += this.state_hander;
        APIConn.Inst.connect();
	}
	
	// Update is called once per frame
	void Update () {
        APIConn.Inst.Update();
	}

    public void LoginButtonClicked() {
        Debug.Log("LoginButtonClicked:"+login_name.text);
        APIConn.Inst.login(login_name.text, login_passwd.text);
    }

    public void ClickTestClicked() {
        Debug.Log("ClickTestClicked");
        JSONObject cmd = new JSONObject();
        cmd.xput("obj", "test");
        cmd.xput("act", "click");
        cmd.xput("data", "anything");
        APIConn.Inst.send_obj(cmd);
    }

    public void response_hander(JSONObject jo) {
        if (jo.s("obj") == "test" && jo.s("act") == "click")
            system_message.text = "server response: "+APIConn.Inst.getUnixTime();
    }

    public void state_hander(JSONObject jo)
    {
        if (jo.s("conn_state") == "IN_SESSION") SceneManager.LoadScene("MainScene");
        //if (jo.s("conn_state") == "LOGIN_SCREEN_ENABLED") SceneManager.LoadScene("LoginScene");
    }
}
