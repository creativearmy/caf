package com.creativearmy.template;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;

public class MyApplication extends Application {

    public static final String ISTUDIO_ACCOUNT = "test2"; //
    public static final String TOOLBOX_ACCOUNT = "test1";

    public static Context context;

    private ImageLoader mImageLoader = null;

    @Override
    public void onCreate() {
        context = getApplicationContext();


        ImageLoaderConfiguration configuration = new ImageLoaderConfiguration.Builder(this)
                .writeDebugLogs() //
                .build();


        mImageLoader = ImageLoader.getInstance();
        mImageLoader.init(configuration);


        Intent startIntent = new Intent(this,NotificationService.class);
        startService(startIntent);

        super.onCreate();
    }

    public ImageLoader getImageLoader() {
        return mImageLoader;
    }
}
