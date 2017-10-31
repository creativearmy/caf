package com.creativearmy.template;

import android.content.Context;
import android.content.SharedPreferences;

public class SharepreferenceUserInfo {
	public static void putValue(Context con, String fileName, String keys,
			String vaule) {
		SharedPreferences sharePf = con.getSharedPreferences(fileName,
				con.MODE_PRIVATE);
		SharedPreferences.Editor edit = sharePf.edit();
		edit.putString(keys, vaule);
		edit.commit();
	}

	public static String getValue(Context con, String fileName, String keys) {
		SharedPreferences sharePf = con.getSharedPreferences(fileName,
				con.MODE_PRIVATE);
		return sharePf.getString(keys, "");
	}

}
