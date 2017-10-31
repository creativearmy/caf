package com.creativearmy.template;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.TextView;
import android.widget.Button;
import android.os.Handler;
import android.os.Message;
import java.util.HashMap;

import com.creativearmy.sdk.APIConnection;
import com.creativearmy.sdk.JSONObject;


public class i000MainActivity extends Activity implements OnClickListener {

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.ixxx_activity_main);


        Button mock_input_click = (Button)findViewById(R.id.INPUT);
        mock_input_click.setOnClickListener(this);

        TextView mock_output = (TextView) findViewById(R.id.OUTPUT);
        mock_output = (TextView) findViewById(R.id.OUTPUT);
    }

    @Override
    protected void onPause() {
        super.onPause();

        APIConnection.removeHandler(handler);
    }

    @Override
    protected void onResume() {
        super.onResume();

        APIConnection.registerHandler(handler);
    }

    public void onClick(View v) {
        if (v.getId() == R.id.INPUT) {

            HashMap data = new HashMap();
            data.put("obj","test");
            data.put("act","input1");
            data.put("data", "click");
            mock_capture_input(data);
        }
    }

    private TextView mock_output;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private final Handler handler = new Handler() {
        public void handleMessage(Message msg) {

        mock_output = (TextView) findViewById(R.id.OUTPUT);

        if (msg.what == APIConnection.responseProperty) {

            JSONObject jo = (JSONObject) msg.obj;

            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // {"obj":"associate","act":"mock","to_login_name":"ISTUDIO_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}
            if (jo.optString("obj").equals("test") && jo.optString("act").equals("output1")) {
                //output.setText(jo.optJSONArray("data").optJSONObject(5).optString("show"));
                //output.setText(jo.a("data").o(5).s("show"));
                //output.setText(jo.optString("data"));
                mock_output.setText(jo.s("data"));
            }

            if (jo.optString("obj").equals("associate") && jo.optString("act").equals("mock")) {
                mock_output.setText("mock resp "+System.currentTimeMillis());
            }

            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        }
        }
    };
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private void mock_capture_input(HashMap data) {
        HashMap req = new HashMap();
        req.put("obj", "associate");
        req.put("act", "mock");
        req.put("to_login_name", MyApplication.TOOLBOX_ACCOUNT);
        req.put("data", data);
        APIConnection.send(req);
    }
}
