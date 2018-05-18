package com.creativearmy.template;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import com.nostra13.universalimageloader.cache.disc.naming.Md5FileNameGenerator;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;
import com.nostra13.universalimageloader.core.assist.QueueProcessingType;

public class MyApplication extends Application {

    public static final String ISTUDIO_ACCOUNT = "test2"; //
    public static final String TOOLBOX_ACCOUNT = "test1";

    public static Context context;

    @Override
    public void onCreate() {

        context = getApplicationContext();

        Intent startIntent = new Intent(this,NotificationService.class);
        startService(startIntent);
        // This configuration tuning is custom. You can tune every option, you may tune some of them,
        // or you can create default configuration by the
        //  ImageLoaderConfiguration.createDefault(this);
        // method.
        //

        // ImageLoader has to init once
        ImageLoaderConfiguration.Builder config = new ImageLoaderConfiguration.Builder(context);
        config.threadPriority(Thread.NORM_PRIORITY - 2);
        config.denyCacheImageMultipleSizesInMemory();
        config.diskCacheFileNameGenerator(new Md5FileNameGenerator());
        config.diskCacheSize(50 * 1024 * 1024); // 50 MiB
        config.tasksProcessingOrder(QueueProcessingType.LIFO);
        config.writeDebugLogs(); // Remove for release app

        // Initialize ImageLoader with configuration.
        ImageLoader.getInstance().init(config.build());

        super.onCreate();
    }

    private final int REQUESTCODE_STORAGE_PERMISSION = 999999999;
    public boolean storagePermitted(Activity activity) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }

        Boolean readPermission = activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
        Boolean writePermission = activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;

        if (readPermission && writePermission) {
            return true;
        }

        activity.requestPermissions(new String[]{ Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE }, REQUESTCODE_STORAGE_PERMISSION);
        return false;
    }

}
