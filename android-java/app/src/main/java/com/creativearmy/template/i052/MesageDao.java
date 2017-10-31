package com.creativearmy.template.i052;

import org.json.JSONException;
import com.creativearmy.sdk.JSONObject;
import com.creativearmy.sdk.JSONArray;

import java.util.List;

public interface MesageDao {
    List<ItemBody> loadData(JSONArray jsonArray);
}
