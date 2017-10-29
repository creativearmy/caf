package com.creativearmy.template.i052;

import android.content.ClipData;
import android.content.Context;
import android.text.TextUtils;

import com.creativearmy.sdk.APIConnection;

import org.json.JSONException;
import com.creativearmy.sdk.JSONObject;
import com.creativearmy.sdk.JSONArray;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by 王杰 on 2015/12/26.
 */
public class MesageDaoImpl implements MesageDao{

    private List<ItemBody> tasks = new ArrayList<ItemBody>();
    private Context context;
    public MesageDaoImpl(Context context){
        this.context = context;
    }
    @Override
    public List<ItemBody> loadData(JSONArray jsonArray) {
//        int length = jsonArray.length();
//        JSONObject taskItem;
//        for (int index = 0; index < length; index++) {
//            taskItem = jsonArray.optJSONObject(index);
//
//            String headImage = taskItem.optString("headfid");//头像
//            String name = taskItem.optString("name");//名字
//            String message = taskItem.optString("message");//内容
//            String time = taskItem.optString("time");//消息时间
//            Integer number = taskItem.optInt("num");//未读消息数目
//            tasks.add(new ItemBody(headImage, name, message, time,number));
//        }



        for(int index=0;index<jsonArray.length();index++){
            JSONObject jsonObject =jsonArray.optJSONObject(index);
            String cid =jsonObject.optString("cid");
            String id =jsonObject.optString("id");
            String last =jsonObject.optString("last");
            String title =jsonObject.optString("title");
            long ut =jsonObject.optLong("ut");
            long vt =jsonObject.optLong("vt");
            String fid=jsonObject.optString("fid");
            String xtype =jsonObject.optString("xtype");
            int count =jsonObject.optInt("count");
            if(TextUtils.isEmpty(fid)){
                fid= APIConnection.server_info.optString("defalut_task_image");
            }
            tasks.add(new ItemBody(cid, id, last, title,ut,vt,xtype,fid,count));
        }
        return tasks;
    }
}
