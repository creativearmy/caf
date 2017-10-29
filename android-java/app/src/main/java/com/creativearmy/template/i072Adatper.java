package com.creativearmy.template;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import java.util.List;

/**
 * Created by CureChen on 2016/3/20 0020.
 */

    public class i072Adatper extends BaseAdapter {

        private LayoutInflater mInflater;
        private Context mContext;
        private List<i072Goodat> mDatas;

        public i072Adatper(Context context, List<i072Goodat> list) {
            this.mDatas = list;
            mInflater = LayoutInflater.from(context);
            mContext = context;
        }

        @Override
        public int getCount() {
            return mDatas.size();
        }

        @Override
        public Object getItem(int position) {
            return mDatas.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN)
        @Override
        public View getView(final int position, View convertView, ViewGroup parent) {
            ViewHolder viewHolder = null;
            if (viewHolder == null) {
                convertView = mInflater.inflate(R.layout.i072_gridview_item,null);
                viewHolder = new ViewHolder();
                viewHolder.mTextView = (TextView) convertView.findViewById(R.id.tv_text);
                convertView.setTag(viewHolder);
            } else {
                viewHolder = (ViewHolder) convertView.getTag();
            }
            final i072Goodat goodat = mDatas.get(position);
            viewHolder.mTextView.setText(goodat.getGaName());
            if(goodat.getGaFlag()) {
                viewHolder.mTextView.setBackground(mContext.getResources().getDrawable(R.drawable.i072_shape_normal));
                viewHolder.mTextView.setTextColor(mContext.getResources().getColor(R.color.gray_i012));
            } else {
                viewHolder.mTextView.setBackground(mContext.getResources().getDrawable(R.drawable.i072_shape));
                viewHolder.mTextView.setTextColor(mContext.getResources().getColor(R.color.black));
            }
            return convertView;
        }

        private class ViewHolder
        {
            TextView mTextView;
        }

}
