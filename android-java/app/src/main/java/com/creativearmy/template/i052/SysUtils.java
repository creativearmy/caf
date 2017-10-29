package com.creativearmy.template.i052;

import android.content.Context;
import android.text.ClipboardManager;

/**
 * Created by storm on 2016/3/27.
 */
public class SysUtils {

    /**
     * 实现文本复制功能
     * @param content
     */
    public static void copy(String content, Context context) {
// 得到剪贴板管理器
        ClipboardManager cmb = (ClipboardManager) context
                .getSystemService(Context.CLIPBOARD_SERVICE);
        cmb.setText(content.trim());
    }
}
