/**
 * 
 */
package com.creativearmy.template.i052;

import android.content.Context;
import android.os.Handler;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import com.creativearmy.template.R;

public class ToastUtil {
	  
	  private static Toast mToast;
	  
	     private static Handler mHandler = new Handler();
	      private static Runnable r = new Runnable() {
	          @Override
			public void run() {
	              mToast.cancel();
	              mToast=null;//
	          }
	      };
	  
	  public static void showShortToast(Context context, String message) {
	    LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
	    View view = inflater.inflate(R.layout.sys_util_toast, null);//
	    TextView text = (TextView) view.findViewById(R.id.toast_message);//
	    text.setText(message);
	    mHandler.removeCallbacks(r);
	        if (mToast == null){//
	        	mToast = new Toast(context);
	    		mToast.setDuration(Toast.LENGTH_SHORT);
	    		mToast.setGravity(Gravity.BOTTOM, 0, 400);
	    		mToast.setView(view);
	        }
	        mHandler.postDelayed(r, 3000);//
	    mToast.show();
	}
}
