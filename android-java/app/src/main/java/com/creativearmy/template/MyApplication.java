package com.creativearmy.template;

import android.app.Application;
import android.content.Context;
import android.content.Intent;

public class MyApplication extends Application {

    public static final String ISTUDIO_ACCOUNT = "test2"; //
    public static final String TOOLBOX_ACCOUNT = "test1";

    public static Context context;

    @Override
    public void onCreate() {

        context = getApplicationContext();

        Intent startIntent = new Intent(this,NotificationService.class);
        startService(startIntent);

        super.onCreate();
    }
}
