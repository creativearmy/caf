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
import com.creativearmy.sdk.JSONObject; // SDK 容错JSON 数据解析库，不会空指针问题


// 界面整合入序列说明： mock_* 相关的不能有的，只有胚片和界面制作验收过程需要
// 开发只要关注：【1】【2】【3】【4】,【1】开发者用户帐号一对的设置在 MyApplication.java
public class i000MainActivity extends Activity implements OnClickListener {

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.ixxx_activity_main);

        // 【2】 胚片界面呈现例子，一个简单用户按键输入， 和 一个简单文字输出
        Button mock_input_click = (Button)findViewById(R.id.INPUT);
        mock_input_click.setOnClickListener(this);

        TextView mock_output = (TextView) findViewById(R.id.OUTPUT);
        mock_output = (TextView) findViewById(R.id.OUTPUT);
    }

    @Override
    protected void onPause() {
        super.onPause();
        // 注消回调监听
        APIConnection.removeHandler(handler);
    }

    @Override
    protected void onResume() {
        super.onResume();
        // 注册一个回调监听
        APIConnection.registerHandler(handler);
    }

    // 【4】 按键按下 是用户输入，调用这里定义的 input 函数，工具箱那边登录后可以观察到
    // 通常这里会收集一些数据，一起发送到服务器。比如一个选日期的界面，这里就应该有用选择的日期
    public void onClick(View v) {
        if (v.getId() == R.id.INPUT) {

            HashMap data = new HashMap();
            data.put("obj","test");
            data.put("act","input1");
            data.put("data", "click");
	        // 通常还有用户在界面输入的其他数据，一起发送好了

            // 界面整合入序列时候，下面一般不用， 直接 APIConnection.send(data);
            // 这里只是打印到工具箱便于验收
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
                                                            // 【服务端数据接收解析呈现区】




            // 【3】 工具箱那里发送 "send input" 后，会发送数据到本APP。这个是模拟服务器 “输出”
            // 如果APP 要响应服务器的输出，像请求响应，或服务器的推送，就可以在这里定义要做的处理
            // 工具箱那里发送"send input"下面这个：
            // 注意这里 obj:act 有两层，嵌套的，我们这边收到的是内层的，内层的data可以是复杂的哈希或数组
            // {"obj":"associate","act":"mock","to_login_name":"ISTUDIO_ACCOUNT","data":{"obj":"test","act":"output1","data":"blah"}}
            if (jo.optString("obj").equals("test") && jo.optString("act").equals("output1")) {
                // 服务器输出，简单的在屏幕上打印这条信息

                // 懒人福气！ 可以缩写的
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
    // 界面整合入序列时候，下面一般不需要， 直接 APIConnection.send(req);
    private void mock_capture_input(HashMap data) {
        HashMap req = new HashMap();
        req.put("obj", "associate");
        req.put("act", "mock");
        req.put("to_login_name", MyApplication.TOOLBOX_ACCOUNT);
        req.put("data", data);
        APIConnection.send(req);
    }
}
