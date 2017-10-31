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
    private Button btnLogin;
    private EditText edtAccount;
    private EditText edtPassword;
    private TextView tvForgetPassword;
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
            PackageInfo pi = pm.getPackageInfo(getPackageName(), 0);//
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
                        Toast.makeText(MainActivity.this,"apk downloaded, install in process",Toast.LENGTH_SHORT).show();
                        installAPK(file.getAbsolutePath());
                    }
                });
            }
        }.start();

    }

    ProgressDialog mProgress;

    private void showDialog() {
        mProgress = new ProgressDialog(this);
        mProgress.setTitle("apk being downloaded");
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
        Log.v("zmh", "downLoadFile started");
        return downloader.downFile(uri, path, name, hand);
    }
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
                    Toast.makeText(MainActivity.this, "download already started", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (!SysUtils.isNetworkAvailable(MainActivity.this)) {
                    Toast.makeText(MainActivity.this, "network failed", Toast.LENGTH_SHORT).show();
                    return;
                }
                int local = getVersionCode();
                startDownloadApk(APIConnection.server_info.optString("apk_url"), mHand);
            }
        });
    }

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

    private void setListener() {
        tvForgetPassword.setOnClickListener(this);
        tvRegister.setOnClickListener(this);
        btnLogin.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {

        HashMap data = new HashMap();

        switch (v.getId()) {
            case R.id.i011_btn_login:
                String strPassword = edtPassword.getText().toString();
                String strAccount = edtAccount.getText().toString();
                if(strAccount.equals("")&&strPassword.equals("")){
                    Toast.makeText(this,"password can not be empty",Toast.LENGTH_SHORT).show();
                    return;
                }

                else if(!strAccount.equals("")&&strPassword.equals("")) {
                    Toast.makeText(this, "enter password", Toast.LENGTH_SHORT).show();
                    return;
                }

                else if (!strPassword.equals("")&&strAccount.equals("")){
                    Toast.makeText(this,"enter account number",Toast.LENGTH_SHORT).show();
                    return;
                }
				
                //APIConnection.credential(strAccount, strPassword);
                //APIConnection.connect();
                APIConnection.login(strAccount, strPassword);
                break;

            case R.id.i011_tv_register:
                tvRegister.setTextColor(0xff95c040);
                Intent intent = new Intent();
                intent.setClass(MainActivity.this, i000MainActivity.class);
                startActivity(intent);

                break;

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
                mTextVersion.setText("my ver:" + getVersionCode() +"  downloadable ver:"+getServeVersion());
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

                        Toast.makeText(MainActivity.this,"login failed",Toast.LENGTH_LONG).show();

                    } else {

                        btnLogin.setEnabled(true);
                        btnLogin.setBackgroundColor(Color.parseColor("#95c040"));
                    }

                } else if (APIConnection.state == APIConnection.States.IN_SESSION) {


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
