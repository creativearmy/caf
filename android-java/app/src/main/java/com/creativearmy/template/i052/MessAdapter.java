package com.creativearmy.template.i052;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;
import com.creativearmy.sdk.JSONObject;

import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;

import java.io.File;
import java.util.ArrayList;

import com.creativearmy.template.R;

public class MessAdapter extends BaseAdapter
{
    /**
     String type_tran; SEND/RECV
     String content; // JSONObject or String
     String from_name ;
     int send_time ;
     String from_id ;
     String from_image;
     String state;
     String xtype ;
     */
    private ArrayList<JSONObject> msgs = new ArrayList<JSONObject>();
    private  Context mContext;
    private DisplayImageOptions options;
    // private ImageLoader imageLoader = null;
    public MessAdapter(Context context) {
        mContext = context;
    }
    private String currentHeader;

    public void addNetMessage(JSONObject msg) {
        msgs.add(msg);
        notifyDataSetChanged();
    }

    //public void  addCurrentUserHeader(String currentHeader)
    //{
    // this.currentHeader=currentHeader;
//    }

    public void addNetMessage(ArrayList<JSONObject> msges) {
        msgs.addAll(msges);
        notifyDataSetChanged();
    }

    public void addHistory(ArrayList<JSONObject> msges) {
        ArrayList<JSONObject> temp = new ArrayList<JSONObject>();
        temp.addAll(msges);
        temp.addAll(msgs);
        msgs.clear();
        msgs.addAll(temp);
        notifyDataSetChanged();
    }
    @Override
    public int getCount() {
        return msgs.size();
    }

    @Override
    public JSONObject getItem(int position) {
        return msgs.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
//        if (convertView == null) {

//        }

        options = new DisplayImageOptions.Builder()
                .showImageOnLoading(R.mipmap.icon_biaoqing_i073)          // 
                .showImageForEmptyUri(R.mipmap.icon_biaoqing_i073)  // 
                .showImageOnFail(R.mipmap.icon_biaoqing_i073)    // 
                .cacheInMemory(true)// 
                        //.displayer(new RoundedBitmapDisplayer(0))  // 
                .cacheOnDisk(true).build();

        LayoutInflater layoutInflater = LayoutInflater.from(parent.getContext());
        CircleImageView imgHead;

        if (msgs.get(position).s("type_tran").equals("SEND"))
        {
            convertView = layoutInflater.inflate(R.layout.chat_right,parent,false);
            imgHead = (CircleImageView) convertView.findViewById(R.id.msg_right_img);
        }
        else
        {
            convertView = layoutInflater.inflate(R.layout.chat_left,parent,false);
            imgHead = (CircleImageView) convertView.findViewById(R.id.msg_left_img);
        }
        TextView timeTxt = (TextView) convertView.findViewById(R.id.msg_time_txt);
        TextView content = (TextView) convertView.findViewById(R.id.msg_content);
        ImageView imageContent = (ImageView) convertView.findViewById(R.id.msg_img_content);

        final JSONObject message = msgs.get(position);
        if (msgs.get(position).s("type_tran").equals("RECV"))
        {
            imgHead.setImageResource(R.drawable.cot_chat_left);
            if(message.s("from_image").equals(""))
                ImageLoader.getInstance().displayImage(APIConnection.server_info.optString("download_path") + APIConnection.server_info.optString("default_image"), imgHead, options);
            else
                ImageLoader.getInstance().displayImage(APIConnection.server_info.optString("download_path") + message.s("from_image"), imgHead, options);


            imgHead.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Intent intent = new Intent();
                   // intent.putExtra(i000MainActivity.EXTRA_ID,message.s("from_id"));
                    Log.d("--------", message.s("from_id"));
                   // intent.setClass(mContext, i000MainActivity.class);
                    mContext.startActivity(intent);
                }
            });
        }else{
            if(TextUtils.isEmpty( message.s("from_image")))
                ImageLoader.getInstance().displayImage(APIConnection.server_info.optString("download_path") + APIConnection.server_info.optString("default_image"), imgHead, options);
            else
                ImageLoader.getInstance().displayImage(APIConnection.server_info.optString("download_path") + message.s("from_image"), imgHead, options);
        }


        if (null != message)
        {
            long nowDate = (long)message.i("send_time");
            if (position != 0)
            {
                long lastDate = (long)msgs.get(position - 1).i("send_time");

                if (nowDate - lastDate > 120)
                {
                    TimeFormatter timeFormat = new TimeFormatter(mContext, nowDate*1000);
                    timeTxt.setText(timeFormat.getDetailTime());
                    timeTxt.setVisibility(View.VISIBLE);
                }
                else
                {
                    timeTxt.setVisibility(View.GONE);
                }
            }
            else
            {
                TimeFormatter timeFormat = new TimeFormatter(mContext, nowDate*1000);
                timeTxt.setText(timeFormat.getDetailTime());
            }

            // plain text
            content.setText(message.s("content"));

            if(message.s("xtype").equals("image")){
                imageContent.setVisibility(View.VISIBLE);
                content.setVisibility(View.GONE);
                ImageLoader.getInstance().displayImage(APIConnection.server_info.optString("download_path") + message.o("content").s("thumb"), imageContent, options);
                imageContent.setOnClickListener(new View.OnClickListener() {
                    private int pos = position;
                    @Override
                    public void onClick(View v) {
                        JSONObject c = msgs.get(position).o("content");
                        downloadAndOpen(APIConnection.server_info.optString("download_path") + c.s("fid"),
                                // mime is used to determine file content type, set during upload
                                // mime type decided at the file server, not the client side
                                c.s("fid")+"."+c.s("mime"));
                    }
                });

            }else {
                content.setOnLongClickListener(new OnCopyListener(mContext,content.getText().toString(),true));
            }


        }
//        String date = TimeFormatter.formatTime(message.time);
//        timeTxt.setText(date);




        return convertView;


    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // click the open various images, audios, files...
    private void downloadAndOpen(final String uuri, final String name) {
        //final File file =null;
        new Thread() {
            @Override
            public void run() {
                super.run();
                final File file=downLoadFile(uuri, name);
                if (file == null) return;
                hd.post(new Runnable() {
                    @Override
                    public void run() {
                        openFile(file);
                    }
                });
            }
        }.start();
    }

    android.os.Handler hd = new android.os.Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
        }
    };

    private void openFile(File file){
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        intent.setAction(Intent.ACTION_VIEW);

        String type = FileUtils.getMIMEType(file);


        intent.setDataAndType(/*uri*/Uri.fromFile(file), type);
        try {
        mContext.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private File downLoadFile(String uri,String name){
        HttpDownloader downloader = new HttpDownloader();
        String path = Environment.getExternalStorageDirectory() + "/CAF/";
        return downloader.downFile(uri, path, name);
    }

}
