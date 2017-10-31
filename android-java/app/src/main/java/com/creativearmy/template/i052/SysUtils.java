package com.creativearmy.template.i052;

import android.content.Context;
import android.text.ClipboardManager;

/**
 * Created by storm on 2016/3/27.
 */
public class SysUtils {

    public static void copy(String content, Context context) {

        ClipboardManager cmb = (ClipboardManager) context
                .getSystemService(Context.CLIPBOARD_SERVICE);
        cmb.setText(content.trim());
    }
}
