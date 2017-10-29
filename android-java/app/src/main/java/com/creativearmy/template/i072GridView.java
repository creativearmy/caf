package com.creativearmy.template;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.GridView;

/**
 * Created by CureChen on 2016/3/20 0020.
 */
public class i072GridView extends GridView {
    public i072GridView(Context context) {
        super(context);
    }

    public i072GridView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public i072GridView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    public void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int expandSpec = MeasureSpec.makeMeasureSpec(Integer.MAX_VALUE >> 2, MeasureSpec.AT_MOST);
        super.onMeasure(widthMeasureSpec, expandSpec);
    }
}
