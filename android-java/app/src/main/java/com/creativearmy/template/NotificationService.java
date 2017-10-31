package com.creativearmy.template;

import com.creativearmy.sdk.JSONObject;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.PowerManager;
import android.provider.Settings;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;

import java.util.List;

public class NotificationService extends Service {


	//private MessageThread messageThread = null;


	private MyApplication app;

	//private Intent I052ChatIntent;
	//private PendingIntent I052ChatPendingIntent = null;



	public int messageChatID = 1000;

	public int messageTaskID = 2000;
	private Notification messageNotification = null;
	private NotificationManager messageNotificatioManager = null;
	private String Chat = "";


	@Override
	public IBinder onBind(Intent intent) {

		return null;
	}

	@Override
	public void onCreate() {

		app = (MyApplication) getApplication();

		APIConnection.registerHandler(handler);
		messageNotificatioManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		super.onCreate();

        checkDozeExclusion();
	}

	private void checkDozeExclusion() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

			String packageName = getPackageName();
			Intent intent = new Intent();
			PowerManager mgr = (PowerManager)this.getSystemService(POWER_SERVICE);

			// check power doze mode exclusion
			if (!mgr.isIgnoringBatteryOptimizations(packageName)) {
				try {

					intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
					intent.setData(Uri.parse("package:" + packageName));
					startActivity(intent);
				} catch (ActivityNotFoundException e) {
					e.printStackTrace();
				}
			} else {
				//intent.setAction(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
				APIConnection.printLog("app is doze whitelised");
			}
		}
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		System.out.println("Notification Service: Start the Service");
		return START_STICKY;
	}

	@Override
	public void onDestroy() {
		System.out.println("Notification Service: Stop the Service");
		super.onDestroy();
	}

	private void notifification(PendingIntent pi, String title, String text) {
		Notification.Builder builder = new Notification.Builder(app.context);
		builder.setContentTitle(title);
		builder.setContentText(text);
		builder.setContentIntent(pi);
		builder.setSmallIcon(R.drawable.icon);
		builder.setAutoCancel(true);
		messageNotification = builder.getNotification();
		builder.setSound(Settings.System.DEFAULT_NOTIFICATION_URI);
		messageNotificatioManager.notify(messageChatID++, messageNotification);
	}

	public void switchActivity(String act) {
		Intent intent = null;


		if (act.equals("i000")) intent = new Intent(app.context, i000MainActivity.class);
		if (act.equals("i072")) intent = new Intent(app.context, i072MainActivity.class);
		if (act.equals("i052")) intent = new Intent(app.context, i052Chatactivity.class);


		if (intent == null) return;
		intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		startActivity(intent);
	}

	private final Handler handler = new Handler() {

		@Override
		public void handleMessage(Message msg) {
			System.out.println("Notification Service: Message Received");


			ActivityManager am = (ActivityManager) app.context.getSystemService(app.context.ACTIVITY_SERVICE);
			List<ActivityManager.RunningTaskInfo> taskInfo = am.getRunningTasks(1);
			ComponentName componentInfo = taskInfo.get(0).topActivity;
			String clsName = componentInfo.getClassName();
				
			if (msg.what == APIConnection.responseProperty) {
				
				int i = 0;
				JSONObject jo = (JSONObject) msg.obj;

				// switch to another activity
				if (jo.optString("obj").equals("sdk") && jo.optString("act").equals("switchreq")) {
					switchActivity(jo.optString("ixxx"));
					return;
				}

				// global error toast, taken care of right here
				if (!jo.optString("ustr").equals("")) {
					Toast.makeText(app.context, jo.optString("ustr"), Toast.LENGTH_SHORT).show();
				}
				// {"obj":"associate", "act":"mock", "to_login_name":"test2", "data":{"obj":"push","act":"test"}}
				if (jo.optString("obj").equals("push")
						&& jo.optString("act").equals("test")) {

					Intent openintent = new Intent(app.context, i000MainActivity.class);
					PendingIntent pendingIntent = PendingIntent.getActivity(app.context, 0, openintent, PendingIntent.FLAG_CANCEL_CURRENT);

					notifification(pendingIntent, "push:test message", "message content");
				}


				if (jo.optString("obj").equals("push")
						&& jo.optString("act").equals("chat_person")) {
						/*
					Chat = jo.optString("chat_content");


					if (clsName.equals(I052ChatActivity.class.getName())&&jo.optString("from_id").equals(I052ChatActivity.mPersonId)) {
						return;
					}

					if (Chat != null && !"".equals(Chat)) {

						//messageChatID++;
//						guyuanbeipingjiacishu = 0;

						Intent openintent = new Intent(app.context, I052ChatActivity.class);
						openintent.putExtra("person_id",jo.optString("from_id"));
						openintent.putExtra("person_name",jo.optString("from_name"));
						PendingIntent I052ChatPendingIntent = PendingIntent.getActivity(app.context, 0, openintent, PendingIntent.FLAG_CANCEL_CURRENT);
						messageNotification.setLatestEventInfo(
								getApplicationContext(),
								jo.optString("person_name"), ""
										+ jo.optString("chat_content"),
								I052ChatPendingIntent);
//						guyuanbeipingjia = false;
//						messageBeipingjiaGuyuanID = messageNotificationID;
						messageNotificatioManager.notify(messageChatID,
								messageNotification);
						Chat = "";
						*/
				}
			}
		}
	};
}
