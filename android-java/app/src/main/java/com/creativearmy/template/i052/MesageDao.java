package com.creativearmy.template.i052;

import org.json.JSONException;
import com.creativearmy.sdk.JSONObject;
import com.creativearmy.sdk.JSONArray;

import java.util.List;

/**
 * Created by 王杰 on 2015/12/26.
 */
public interface MesageDao {
    List<ItemBody> loadData(JSONArray jsonArray);
}
