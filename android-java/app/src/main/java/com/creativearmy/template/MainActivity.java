package com.creativearmy.template;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;
import com.creativearmy.sdk.JSONObject;


import java.io.File;
import java.util.HashMap;

public class MainActivity extends Activity implements View.OnClickListener {
    /**
     * 登录按钮
     */
    private Button btnLogin;
    /**
     * 账号的编辑框
     */
    private EditText edtAccount;
    /**
     * 密码的编辑框
     */
    private EditText edtPassword;
    /**
     * 忘记密码的TextView
     */
    private TextView tvForgetPassword;
    /**
     * 注册we的TextView
     */
    private TextView tvRegister;

    private TextView mTextVersion;
    private boolean mIsDownloa = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.activity_main);

        // init APIConnection right away
        APIConnection.init_asap(getApplicationContext());
        try {
            APIConnection.client_info.put("xtype", "android");
        } catch (Exception e) {}

        APIConnection.registerHandler(handler);
        APIConnection.wsURL = "ws://112.124.70.60:51727/demo";
        APIConnection.connect();

        initViews();
        binEdt();
        setListener();
    }


    private int getVersionCode() {
        PackageManager pm = getPackageManager();
        try {
            PackageInfo pi = pm.getPackageInfo(getPackageName(), 0);//getPackageName()是你当前类的包名，0代表是获取版本信息
            return pi.versionCode;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }

    }

    private String getServeVersion(){
        return APIConnection.server_info.optString("android_version_number");
    }

    private void startDownloadApk(final String uuri,final Handler hd) {
        showDialog();
        new Thread() {
            @Override
            public void run() {
                super.run();
                final File file=downLoadFile(uuri, "android.apk",hd);
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        mProgress.dismiss();
                        mIsDownloa=false;
                        Toast.makeText(MainActivity.this,"新版本apk下载成功，开始安装",Toast.LENGTH_SHORT).show();
                        installAPK(file.getAbsolutePath());
                    }
                });
            }
        }.start();

    }

    ProgressDialog mProgress;

    private void showDialog() {
        mProgress = new ProgressDialog(this);
        mProgress.setTitle("正在下载新版本");
        mProgress.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        mProgress.setCanceledOnTouchOutside(false);
        mProgress.setProgress(0);
        mProgress.show();
    }

    private void installAPK(String str){
        //String fileName = Environment.getExternalStorageDirectory() + str;
        String fileName = str;
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(Uri.fromFile(new File(fileName)), "application/vnd.android.package-archive");
        startActivity(intent);
    }

    Handler mHand = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            mProgress.setProgress(msg.what);
        }
    };

    private File downLoadFile(String uri, String name,Handler hand) {
        HttpDownloader downloader = new HttpDownloader();
        String path = Environment.getExternalStorageDirectory() + "/test/";
        Log.v("zmh", "downLoadFile 开始下载文件");
        return downloader.downFile(uri, path, name, hand);
    }
    /**
     * 处理所有的初始化
     */
    private void initViews() {
        btnLogin = (Button) this.findViewById(R.id.i011_btn_login);

        if (APIConnection.state != APIConnection.States.LOGIN_SCREEN_ENABLED) {
            // wait for first server connection
            btnLogin.setEnabled(false);
            btnLogin.setBackgroundColor(Color.GRAY);
        }

        edtAccount = (EditText) this.findViewById(R.id.i011_edt_account);
        edtPassword = (EditText) this.findViewById(R.id.i011_edt_password);
        tvForgetPassword = (TextView) this.findViewById(R.id.i011_tv_forget_password);
        tvRegister = (TextView) this.findViewById(R.id.i011_tv_register);
        mTextVersion=(TextView)findViewById(R.id.text_version);

        mTextVersion.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mIsDownloa) {
                    Toast.makeText(MainActivity.this, "正在下载新版本，请不要重复下载", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (!SysUtils.isNetworkAvailable(MainActivity.this)) {
                    Toast.makeText(MainActivity.this, "网络不可用", Toast.LENGTH_SHORT).show();
                    return;
                }
                int local = getVersionCode();
                startDownloadApk(APIConnection.server_info.optString("apk_url"), mHand);
            }
        });
    }

    /**
     * 绑定用户名输入框的监听
     */
    private void binEdt() {
        String UserName = SharepreferenceUserInfo.getValue(getApplicationContext(), "Account", "Uname");
        if(!"".equals(UserName))
        {
            edtAccount.setText(UserName);
            edtPassword.requestFocus();
        }
        String Passwd = SharepreferenceUserInfo.getValue(getApplicationContext(), "Account", "Passwd");
        if(!"".equals(Passwd)) edtPassword.setText(Passwd);

    }

    /**
     * 设置所有的监听事件
     */
    private void setListener() {
        tvForgetPassword.setOnClickListener(this);
        tvRegister.setOnClickListener(this);
        btnLogin.setOnClickListener(this);
    }

    /**
     * 处理所有的点击事件
     */
    @Override
    public void onClick(View v) {

        HashMap data = new HashMap();

        switch (v.getId()) {
            /**
             * 登录按钮事件,获取账号和密码
             * */
            case R.id.i011_btn_login:
                String strPassword = edtPassword.getText().toString();
                String strAccount = edtAccount.getText().toString();
                /**
                 *账号和密码都是空
                 * */
                if(strAccount.equals("")&&strPassword.equals("")){
                    Toast.makeText(this,"账号密码不能为空",Toast.LENGTH_SHORT).show();
                    return;
                }

                 /**
                 * 账号不为空，密码等于空的时候
                 * */
                else if(!strAccount.equals("")&&strPassword.equals("")) {
                    Toast.makeText(this, "请输入密码", Toast.LENGTH_SHORT).show();
                    return;
                }

                /**
                 * 账号等于空，密码不为空
                 * */
                else if (!strPassword.equals("")&&strAccount.equals("")){
                    Toast.makeText(this,"请输入账号",Toast.LENGTH_SHORT).show();
                    return;
                }
				
                //APIConnection.credential(strAccount, strPassword);
                //APIConnection.connect();
                APIConnection.login(strAccount, strPassword);
                break;

            /**
             * 注册We>>的TextView事件
             * */
            case R.id.i011_tv_register:
                tvRegister.setTextColor(0xff95c040);
                Intent intent = new Intent();
                intent.setClass(MainActivity.this, i000MainActivity.class);
                startActivity(intent);

                break;

            /**
             * 忘记密码的TextView事件
             * */
            case R.id.i011_tv_forget_password:
                tvForgetPassword.setTextColor(0xff95c040);
                Intent intent1 = new Intent();
                intent1.setClass(MainActivity.this, i000MainActivity.class);
                startActivity(intent1);
                break;

        }
    }
    @Override
    protected void onDestroy() {
        APIConnection.removeHandler(handler);
        super.onDestroy();
    }

    private final Handler handler = new Handler() {
        public void handleMessage(Message msg) {
            if(APIConnection.server_info!=null){
                mTextVersion.setText("我的版本:" + getVersionCode() +"  可更新版本:"+getServeVersion());
            }
           // TextView output = (TextView) findViewById(R.id.OUTPUT);
                JSONObject jo = (JSONObject) msg.obj;
            if (msg.what == APIConnection.responseProperty) {

                if (jo.optString("obj").equals("person") && jo.optString("act").equals("login")) {

                     if(jo.optJSONObject("user_info")!=null){

                     }
                }
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }

            if (msg.what == APIConnection.stateProperty) {
                if (APIConnection.state == APIConnection.States.LOGIN_SCREEN_ENABLED) {
                    if (APIConnection.from_state == APIConnection.States.INITIAL_LOGIN || APIConnection.from_state == APIConnection.States.SESSION_LOGIN) {

                        Toast.makeText(MainActivity.this,"登陆失败",Toast.LENGTH_LONG).show();

                    } else {

                        btnLogin.setEnabled(true);
                        btnLogin.setBackgroundColor(Color.parseColor("#95c040"));
                    }

                } else if (APIConnection.state == APIConnection.States.IN_SESSION) {

                        //登陆成功保存用户账号
                        SharepreferenceUserInfo.putValue(getApplicationContext(), "Account", "Uname", edtAccount.getText().toString());
                        SharepreferenceUserInfo.putValue(getApplicationContext(), "Account", "Passwd", edtPassword.getText().toString());

                        Intent intent=new Intent();
                        intent.setClass(MainActivity.this,i000MainActivity.class);
                        startActivity(intent);
                        finish();
                }
            }
        }
    };

}
