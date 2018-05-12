using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using APIConnection;

public class MainScene : MonoBehaviour {

    public GameObject cube;

	// Use this for initialization
	void Start () {
        APIConn.Inst.response_received_handlers += this.response_handler;
	}
	
	// Update is called once per frame
	void Update () {
        APIConn.Inst.Update();
	}

    public void response_handler (JSONObject jo) {
        
        Debug.Log("mainscene response_handler");

        if (jo.s("obj") == "test" && jo.s("act") == "scale")
        {
            if (jo.i("scale") == 0)
            {
                cube.gameObject.transform.localScale -= new Vector3((float)0.1, (float)0.1, (float)0.1);
            }
            else
            {
                cube.gameObject.transform.localScale -= new Vector3(jo.i("scale"), jo.i("scale"), jo.i("scale"));
            }
        }
    }

    public void ButtonClicked () {
        JSONObject cmd = new JSONObject();
        cmd.xput("obj", "test");
        cmd.xput("act", "scale");
        APIConn.Inst.send_obj(cmd);
    }
}
