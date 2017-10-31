package com.creativearmy.template;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;
import com.creativearmy.sdk.JSONArray;
import com.creativearmy.sdk.JSONObject;
import com.lidroid.xutils.HttpUtils;
import com.lidroid.xutils.exception.HttpException;
import com.lidroid.xutils.http.RequestParams;
import com.lidroid.xutils.http.ResponseInfo;
import com.lidroid.xutils.http.callback.RequestCallBack;
import com.lidroid.xutils.http.client.HttpRequest;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;

import org.json.JSONException;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import static java.util.Calendar.getInstance;

public class i072MainActivity extends Activity {


    private String fid = null;
    private String pid = null;

    private static final int PHOTO_REQUEST_CAREMA = 0;

    private Uri     rawImageUri = Uri.parse("file://" + "/" + Environment.getExternalStorageDirectory().getPath() + "/" + "raw.jpg");
    private String  smallImageFileName = Environment.getExternalStorageDirectory().getPath() + "/" + "small.jpg";
    private Uri     smallImageURI = Uri.parse("file://" + "/" + smallImageFileName);;

    private CircleImageView iv_personImage;
    private File tempFile;
    private Bitmap bitmapTemp = null;
    private static final int PHOTO_REQUEST_GALLERY_CIRCLE = 3;
    private static final int PHOTO_REQUEST_CUT_CIRCLE = 5;
    private ImageView ivTemp;

    private ImageView iv_choosemale;
    private ImageView iv_choosefemale;
    private ImageView iv_male;
    private ImageView iv_female;
    private ImageView i720_return;
    private ImageView i720_save;
    private ImageLoader imageLoader = null;
    private DisplayImageOptions options;


    private Spinner sp_goodat;
    ArrayList<String> goodatList;
    ArrayAdapter<String> adapter;
    private GridView gv_goodat;
    private com.creativearmy.template.i072Adatper i072Adatper;
    private List<i072Goodat> mdata = null;

    private EditText name,gender,singnature,phoneNo,address,work_experience,edu_experience,payment,provience ,city;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        goodatList = new ArrayList<>();
        mdata = new ArrayList<>();
        setContentView(R.layout.i072_activity_main);
        APIConnection.registerHandler(handler);
        imageLoader = ((MyApplication)getApplication()).getImageLoader();
        options = new DisplayImageOptions.Builder()
                .showImageOnLoading(R.mipmap.icon_biaoqing_i073)          
                .showImageForEmptyUri(R.mipmap.icon_biaoqing_i073)  
                .showImageOnFail(R.mipmap.icon_biaoqing_i073)       
                .cacheInMemory(true)                        
                .cacheOnDisk(true)                          
//            .displayer(new RoundedBitmapDisplayer(20))  
                .build();
        init();

        // edit someone else as well, like dummy
        pid =  getIntent().getStringExtra("PID");
        if (pid == null) {
            pid = APIConnection.user_info.optString("_id");
        }
        getInfo();
//

//        mock_startup();

    }
    @Override
    protected void onResume() {
        super.onResume();
    }

    private void init(){
        iv_male=(ImageView) findViewById(R.id.iv_male_i072);
        iv_female=(ImageView) findViewById(R.id.iv_female_i072);
        iv_choosemale=(ImageView) findViewById(R.id.imachoosemale_i072);
        iv_choosefemale=(ImageView) findViewById(R.id.imachoosefemale_i072);
        iv_personImage=(CircleImageView) findViewById(R.id.ima_head_i072);
        findViewById(R.id.i072_return).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
        findViewById(R.id.i072_save).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                updateInfo();
            }
        });

        singnature = (EditText) findViewById(R.id.singnature);
        name = (EditText) findViewById(R.id.name);
//        gender = (EditText) findViewById(R.id.gender);
        phoneNo = (EditText) findViewById(R.id.phoneNo);
        address = (EditText) findViewById(R.id.address);
        work_experience = (EditText) findViewById(R.id.work_experience);
        edu_experience = (EditText) findViewById(R.id.edu_experience);
        payment = (EditText) findViewById(R.id.payment_i072);
        provience = (EditText) findViewById(R.id.edt_provience);
        city = (EditText) findViewById(R.id.edt_city);
        sp_goodat = (Spinner) findViewById(R.id.sp_goodat_i072);

        gv_goodat = (GridView) findViewById(R.id.gv_goodat_i072);
        gv_goodat.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                i072Goodat i072Goodat = (com.creativearmy.template.i072Goodat) i072Adatper.getItem(position);
                String key = i072Goodat.getGaKey();
                for (com.creativearmy.template.i072Goodat i:mdata) {
                    if (i.getGaKey().equals(key)) {
                        i.setGaFlag(!i.getGaFlag());
                    }
                }
                i072Adatper = new i072Adatper(i072MainActivity.this,mdata);
                gv_goodat.setAdapter(i072Adatper);
            }
        });
    }
    public String selectSex(){
        if(iv_choosefemale.getVisibility() == View.INVISIBLE){
            return "male";
        }else{
            return "female";
        }
    }
    public void setSex(String sex){
        if (sex.equals("male")){
            iv_choosemale.setVisibility(ViewGroup.VISIBLE);
            iv_choosefemale.setVisibility(ViewGroup.INVISIBLE);
        }else{
            iv_choosefemale.setVisibility(ViewGroup.VISIBLE);
            iv_choosemale.setVisibility(ViewGroup.INVISIBLE);
        }
    }

    public void ivmaleClick(View v){
        iv_choosemale.setVisibility(ViewGroup.VISIBLE);
        iv_choosefemale.setVisibility(ViewGroup.INVISIBLE);
    }
    public void ivfemaleClick(View v){
        iv_choosefemale.setVisibility(ViewGroup.VISIBLE);
        iv_choosemale.setVisibility(ViewGroup.INVISIBLE);
    }
    public void changePersonImage(View v){
        showPhotoDialog();
    }
    public void gallery(View view,int requestCode) {

        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");

        startActivityForResult(intent, requestCode);
    }
    private File saveImg(Bitmap b){
        File f = new File(getCacheDir()+"/"+getInstance().getTimeInMillis()
                + ".jpg");
        if (f.exists()) {
            f.delete();
        }
        try {
            FileOutputStream out = new FileOutputStream(f);
            b.compress(Bitmap.CompressFormat.JPEG, 90, out);
            out.flush();
            out.close();
            return f;

        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        return null;
    }
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == PHOTO_REQUEST_GALLERY_CIRCLE) {

            if (data != null) {

                Uri uri = data.getData();
//                tempFile = new File(getCacheDir()+"/call/"+getInstance().getTimeInMillis()
//                        + ".jpg");
//                        imageUri = Uri.fromFile(tempFile);
                crop(uri, requestCode);
            }
        }
        else if (requestCode == PHOTO_REQUEST_CAREMA) {
            cropRawImageUri(rawImageUri);

        }else if (requestCode == PHOTO_REQUEST_CUT_CIRCLE) {

//            if (data != null) {
                Log.i("Test", APIConnection.server_info.optString("upload_to"));
                RequestParams rp = new RequestParams();
//                Bitmap bitmap = setPicToView(data);
//                File f = saveImg(SysUtils
//                        .getRoundedCornerBitmap(bitmap));
//                iv_personImage.setImageBitmap(SysUtils
//                        .getRoundedCornerBitmap(bitmap));


            if (imageLoader != null && iv_personImage != null){
                imageLoader.displayImage(String.valueOf(smallImageURI), iv_personImage, options);
            }

//                Log.i("Test", "File is Not :" + (f.isFile() ? "yes" : "No"));
            File f = new File(smallImageFileName);
                rp.addBodyParameter("local_file", f);
                rp.addBodyParameter("proj", APIConnection.server_info.optString("proj"));
                HttpUtils h = new HttpUtils();
                h.send(HttpRequest.HttpMethod.POST, APIConnection.server_info.optString("upload_to"), rp, new RequestCallBack<Object>() {
                    @Override
                    public void onSuccess(ResponseInfo<Object> responseInfo) {
                        try {
                            JSONObject jb = new JSONObject(responseInfo.result.toString());
                            fid = jb.optString("fid");
                            Log.i("upload return fid:", fid);
                            if (jb.optString("fid") != null && !jb.optString("fid").equals("")) {
                                Toast.makeText(i072MainActivity.this, "Upload success", Toast.LENGTH_LONG).show();

//                                updateInfo();
                            }

//                            tempFile.delete();

                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }

                    @Override
                    public void onFailure(HttpException e, String s) {
                        Log.i("Test", s);
                        Toast.makeText(i072MainActivity.this, "Avatar upload failed", Toast.LENGTH_SHORT).show();
                    }
                });



//                this.ivTemp.setImageBitmap(SysUtils.getRoundedCornerBitmap(setPicToView(data)));
//            }


        }

        super.onActivityResult(requestCode, resultCode, data);
    }
    public void crop(Uri uri, int requestCode) {

        Intent intent = new Intent("com.android.camera.action.CROP");
        intent.setDataAndType(uri, "image/*");
        intent.putExtra("crop", "true");

        intent.putExtra("aspectX", 1);
        intent.putExtra("aspectY", 1);

        intent.putExtra("outputX", 250);
        intent.putExtra("outputY", 250);
        intent.putExtra("outputFormat", "JPEG");// 
        intent.putExtra("noFaceDetection", true);// 
        intent.putExtra("return-data", false);
//        uritempFile = Uri.parse("file://" + "/" + smallImageFileName);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, smallImageURI);
//        intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri); // 

        startActivityForResult(intent, PHOTO_REQUEST_CUT_CIRCLE);
    }
    private void cropRawImageUri(Uri uri) {


        Intent intent = new Intent("com.android.camera.action.CROP");

        intent.setType("image/*");

        intent.setDataAndType(uri, "image/*");

        intent.putExtra("crop", "true");

        intent.putExtra("aspectX", 1);

        intent.putExtra("aspectY", 1);

        intent.putExtra("outputX", 250);

        intent.putExtra("outputY", 250);
        //smallImageURI = Uri.parse("file://" + "/" + smallImageFileName);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, smallImageURI);
//        intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri); // 
        intent.putExtra("outputFormat", "JPEG");// 
        intent.putExtra("noFaceDetection", true);// 
        intent.putExtra("return-data", true);


        startActivityForResult(intent, PHOTO_REQUEST_CUT_CIRCLE);




    }
    private Bitmap setPicToView(Intent picdata) {
        Bundle bundle = picdata.getExtras();
        if (bundle != null) {
            Bitmap photo = (Bitmap)bundle.getParcelable("data");
            return photo;
        }
        return null;
    }

    private void showPhotoDialog() {
        final AlertDialog dlg = new AlertDialog.Builder(this).create();
        dlg.show();
        Window window = dlg.getWindow();
        window.setContentView(R.layout.i072_search_local_image_dialog);

        TextView tv_paizhao = (TextView) window.findViewById(R.id.tv_content1);
        tv_paizhao.setText("Camera");
        tv_paizhao.setOnClickListener(new OnClickListener() {
            @SuppressLint("SdCardPath")
            public void onClick(View v) {

                // imageName = getNowTime() + ".png";
                // Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                Intent intent = new Intent("android.media.action.IMAGE_CAPTURE");

                //tempFile = new File(getCacheDir()+"/"+getInstance().getTimeInMillis()
                //        + ".jpg");

                //imageUri = Uri.fromFile(tempFile);

                intent.putExtra(MediaStore.EXTRA_OUTPUT, rawImageUri);

                startActivityForResult(intent, PHOTO_REQUEST_CAREMA);

                ivTemp =iv_personImage;

//	                intent.putExtra(MediaStore.EXTRA_OUTPUT,
//	                        Uri.fromFile(new File("/sdcard/fanxin/", imageName)));
                //startActivityForResult(intent, PHOTO_REQUEST_TAKEPHOTO);
                dlg.cancel();
            }
        });
        TextView tv_xiangce = (TextView) window.findViewById(R.id.tv_content2);
        tv_xiangce.setText("album");
        tv_xiangce.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                Intent intent = new Intent(Intent.ACTION_PICK, null);

                gallery(v, PHOTO_REQUEST_GALLERY_CIRCLE);
                ivTemp = iv_personImage;
                dlg.cancel();
            }
        });
    }

    // 1
    private final String i_account = "11111111111";
    private final String t_account = "15798001012";
    private final Handler handler = new Handler() {
        public void handleMessage(Message msg) {
            TextView output = (TextView) findViewById(R.id.OUTPUT);
            if (msg.what == APIConnection.responseProperty) {
                JSONObject jo = (JSONObject) msg.obj;
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                // {"obj":"associate","act":"mock","to_login_name":"test6977","data":{"obj":"test","act":"output1","data":"blah"}}
                if (jo.optString("obj").equals("test") && jo.optString("act").equals("output1")) {

                    output.setText(jo.optString("data"));
                }else if(jo.optString("obj").equals("person") && jo.optString("act").equals("update")){
                    if (jo.optString("status").equals("success")){
                        Log.e("success------", jo.toString());
                        Toast.makeText(i072MainActivity.this, "update success", Toast.LENGTH_SHORT).show();
                        Intent intent=new Intent();
                        intent.putExtra("name",name.getEditableText().toString());
                        intent.putExtra("uri",String.valueOf(smallImageURI));
                        setResult(0x123, intent);
                        finish();
                    }else{
                        Toast.makeText(i072MainActivity.this, "update success", Toast.LENGTH_SHORT).show();
                    }
                }else if(jo.optString("obj").equals("person") && jo.optString("act").equals("get")){
                    JSONObject data = jo.optJSONObject("data");
                    fid = data.optString("headFid");
                    name.setText(data.optString("name"));
                    phoneNo.setText(data.optString("phoneNo"));
                    address.setText(data.optString("address"));
                    work_experience.setText(data.optString("work_experience"));
                    edu_experience.setText(data.optString("edu_experience"));
                    singnature.setText(data.optString("singnature"));
                    city.setText(data.optString("city"));
                    provience.setText(data.optString("province"));
                    payment.setText(data.optString("payment"));
                    JSONArray array = data.optJSONArray("fields");
                    setSex(data.optString("gender"));
                    try {
                        initAdapterData(goodatList);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    sp_goodat.setAdapter(adapter);
                    i072Adatper = new i072Adatper(i072MainActivity.this,getGoodatData(data.optJSONArray("fields"),generateData(APIConnection.server_info.optJSONArray("field_labels"),mdata)));
                    gv_goodat.setAdapter(i072Adatper);
                    imageLoader.displayImage(APIConnection.server_info.optString("download_path") + data.optString("headFid"), iv_personImage, options);


                }

                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }

            if (msg.what == APIConnection.stateProperty) {
                if (APIConnection.state == APIConnection.States.IN_SESSION) {
                    //output.setText("Login OK");

                    getInfo();
                }
            }
        }
    };

    private void input(HashMap data) {
        HashMap req = new HashMap();
        req.put("obj", "associate");
        req.put("act", "mock");
        req.put("to_login_name", t_account);
        req.put("data", data);
        APIConnection.send(req);
    }


    private void getInfo(){
        HashMap hash = new HashMap();
        hash.put("obj","person");
        hash.put("act","get");
        hash.put("person_id",pid);
        APIConnection.send(hash);
    }

    private void updateInfo(){
        HashMap hash = new HashMap();
        hash.put("obj","person");
        hash.put("act","update");
        hash.put("person_id",pid);
        HashMap update_date = new HashMap();
        update_date.put("headFid",fid);
        update_date.put("name",name.getText().toString());
        update_date.put("gender",selectSex());
        update_date.put("phoneNo",phoneNo.getText().toString());
        update_date.put("address",address.getText().toString());
        update_date.put("work_experience",work_experience.getText().toString());
        update_date.put("edu_experience",edu_experience.getText().toString());
        update_date.put("payment",payment.getText().toString());
        update_date.put("singnature", singnature.getText().toString());
        update_date.put("province", provience.getText().toString().trim());
        update_date.put("city", city.getText().toString().trim());
        update_date.put("fields", toJsonArray(mdata));
        hash.put("update_date", update_date);
        Log.e("update---",new JSONObject(hash).toString());
        APIConnection.send(hash);
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private void initAdapterData(List<String> mItems) throws JSONException {
        JSONObject object = APIConnection.server_info.optJSONObject("field_map");
//        JSONArray ja = new JSONArray(i072Goodat.class);
//        Log.e("---", object.toJSONArray(ja) + "");
        APIConnection.server_info.optJSONArray("field_keys");
        APIConnection.server_info.optJSONObject("field_map");
        APIConnection.server_info.optJSONObject("field_note_map");
        Log.e("---", APIConnection.server_info.optJSONArray("field_keys") + "");
        Log.e("---", APIConnection.server_info.optJSONObject("field_map") + "");
        Log.e("---", APIConnection.server_info.optJSONObject("field_note_map") + "");
        //adapter = new ArrayAdapter<String>(this,android.R.layout.simple_spinner_item, generateData(APIConnection.server_info.optJSONArray("field_keys"), goodatList));
    }

    private List<i072Goodat> generateData(JSONArray array, List<i072Goodat> list) {
        for (int i = 0; i <array.length(); i++) {
            i072Goodat i072Goodat = new i072Goodat();
            String content = array.optString(i);
            i072Goodat.setGaName(content);
            i072Goodat.setGaKey(i+"");
            list.add(i072Goodat);
        }
        return list;
    }

    private List<i072Goodat> getGoodatData(JSONArray array, List<i072Goodat> list){
        for (i072Goodat a : list) {
            for (int i = 0; i < array.length(); i++) {
                if (array.optString(i).equals(a.getGaName())) {
                    a.setGaFlag(true);
                    break;
                }
            }
        }
        return list;
    }

    private JSONArray toJsonArray(List<i072Goodat> list) {
        JSONArray jsonArray = new JSONArray();
        for (i072Goodat i : list) {
            if (i.getGaFlag() == true) {
                jsonArray.put(i.getGaName());
            }
        }
        return  jsonArray;
    }



}
