package com.creativearmy.template;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Message;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;

public class MyApplication extends Application {

    // 【1】开发者应该注册两个帐号，一个在工具箱登录，一个是本程序APP登录用的。test1 - test100000 10万个都可以选。避免与别人在用的冲突
    // ISTUDIO_ACCOUNT 是本程序APP用的，TOOLBOX_ACCOUNT 是工具箱登录用的。工具箱登录后可以观察APP发送的数据，也可以给APP发送数据
    // APP 发送的数据叫 “输入” 调用这里定义的 input 函数，输入可以是用户输入，界面操作，按键按下等
    public static final String ISTUDIO_ACCOUNT = "test2"; //
    public static final String TOOLBOX_ACCOUNT = "test1";

    private int auto_login_attemps_max = 1;

    public static Context context;

    private ImageLoader mImageLoader = null;

    @Override
    public void onCreate() {
        context = getApplicationContext();

        //创建默认的ImageLoader配置参数
        ImageLoaderConfiguration configuration = new ImageLoaderConfiguration.Builder(this)
                .writeDebugLogs() //打印log信息
                .build();


        //Initialize ImageLoader with configuration.
        mImageLoader = ImageLoader.getInstance();
        mImageLoader.init(configuration);


        Intent startIntent = new Intent(this,NotificationService.class);
        startService(startIntent);

        super.onCreate();
    }

    public ImageLoader getImageLoader() {
        return mImageLoader;
    }
    public void setImageLoader(ImageLoader imageLoader) {
        mImageLoader = imageLoader;
    }
}
