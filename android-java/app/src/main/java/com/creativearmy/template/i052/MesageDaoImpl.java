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

public class MesageDaoImpl implements MesageDao{

    private List<ItemBody> tasks = new ArrayList<ItemBody>();
    private Context context;
    public MesageDaoImpl(Context context){
        this.context = context;
    }
    @Override
    public List<ItemBody> loadData(JSONArray jsonArray) {



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
