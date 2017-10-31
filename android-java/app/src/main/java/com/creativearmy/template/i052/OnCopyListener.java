package com.creativearmy.template.i052;

import android.content.Context;
import android.view.View;
import android.widget.Toast;

/**
 * Created by storm on 2016/3/27.
 */
public class OnCopyListener implements View.OnLongClickListener {
    private Context mContext;
    private String content;
    private boolean showToast;
    public  OnCopyListener(Context mContext,String content,boolean showToast)
    {
        this.mContext=mContext;
        this.content=content;
        this.showToast=showToast;
    }
    @Override
    public boolean onLongClick(View v) {
        SysUtils.copy(content, mContext);
        if(showToast)
            Toast.makeText(mContext, "copy succeed", Toast.LENGTH_SHORT).show();
        return false;
    }
}
