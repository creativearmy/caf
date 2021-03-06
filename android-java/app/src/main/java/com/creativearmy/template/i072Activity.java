package com.creativearmy.template;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
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
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.creativearmy.sdk.APIConnection;
import com.creativearmy.sdk.JSONObject;
import com.lidroid.xutils.HttpUtils;
import com.lidroid.xutils.exception.HttpException;
import com.lidroid.xutils.http.RequestParams;
import com.lidroid.xutils.http.ResponseInfo;
import com.lidroid.xutils.http.callback.RequestCallBack;
import com.lidroid.xutils.http.client.HttpRequest;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import static java.util.Calendar.getInstance;

public class i072Activity extends Activity {

    // Demo how a file is uploaded to HTTP server
    // Set a break point, and click on the avatar on emulator to upload an image from album
    // or from new camera shot, to file server.

    private String fid = null;

    private String pid = null;

    private static final int PHOTO_REQUEST_CAREMA = 0;

    private Uri     rawImageUri = Uri.parse("file://" + "/" + Environment.getExternalStorageDirectory().getPath() + "/" + "raw.jpg");
    private String  smallImageFileName = Environment.getExternalStorageDirectory().getPath() + "/" + "small.jpg";
    private Uri     smallImageURI = Uri.parse("file://" + "/" + smallImageFileName);;

    private CircleImageView iv_personImage;
    private static final int PHOTO_REQUEST_GALLERY_CIRCLE = 3;
    private static final int PHOTO_REQUEST_CUT_CIRCLE = 5;
    private ImageView ivTemp;

    private ImageView iv_choosemale;
    private ImageView iv_choosefemale;

    private DisplayImageOptions options;

    private EditText name,singnature,phoneNo,address,work_experience,edu_experience,payment,provience,city;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.i072activity);

        APIConnection.registerHandler(handler);

        options = new DisplayImageOptions.Builder()
                .showImageOnLoading(R.mipmap.icon_biaoqing_i073)          
                .showImageForEmptyUri(R.mipmap.icon_biaoqing_i073)  
                .showImageOnFail(R.mipmap.icon_biaoqing_i073)       
                .cacheInMemory(true)                        
                .cacheOnDisk(true)                          
                .build();

        init();

        pid =  getIntent().getStringExtra("PID");

        if (pid == null) {
            pid = APIConnection.user_info.optString("_id");
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    private void init(){
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
        phoneNo = (EditText) findViewById(R.id.phoneNo);
        address = (EditText) findViewById(R.id.address);
        work_experience = (EditText) findViewById(R.id.work_experience);
        edu_experience = (EditText) findViewById(R.id.edu_experience);
        payment = (EditText) findViewById(R.id.payment_i072);
        provience = (EditText) findViewById(R.id.edt_provience);
        city = (EditText) findViewById(R.id.edt_city);
    }

    public String selectSex() {
        if(iv_choosefemale.getVisibility() == View.INVISIBLE){
            return "male";
        } else {
            return "female";
        }
    }

    public void setSex(String sex) {
        if (sex.equals("male")) {
            iv_choosemale.setVisibility(ViewGroup.VISIBLE);
            iv_choosefemale.setVisibility(ViewGroup.INVISIBLE);
        }else{
            iv_choosefemale.setVisibility(ViewGroup.VISIBLE);
            iv_choosemale.setVisibility(ViewGroup.INVISIBLE);
        }
    }

    public void ivmaleClick(View v) {
        iv_choosemale.setVisibility(ViewGroup.VISIBLE);
        iv_choosefemale.setVisibility(ViewGroup.INVISIBLE);
    }

    public void ivfemaleClick(View v) {
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

    private File saveImg(Bitmap b) {

        File f = new File(getCacheDir()+"/"+getInstance().getTimeInMillis() + ".jpg");

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
                crop(uri, requestCode);
            }

        } else if (requestCode == PHOTO_REQUEST_CAREMA) {

            cropRawImageUri(rawImageUri);

        } else if (requestCode == PHOTO_REQUEST_CUT_CIRCLE) {

            Log.i("i072", APIConnection.server_info.optString("upload_to"));

            RequestParams req = new RequestParams();

            if (iv_personImage != null) {
                ImageLoader.getInstance().displayImage(String.valueOf(smallImageURI), iv_personImage, options);
            }

            File file = new File(smallImageFileName);

            req.addBodyParameter("local_file", file);
            req.addBodyParameter("proj", APIConnection.server_info.optString("proj"));

            HttpUtils http = new HttpUtils();

            http.send(HttpRequest.HttpMethod.POST, APIConnection.server_info.optString("upload_to"), req, new RequestCallBack<Object>() {

                @Override
                public void onSuccess(ResponseInfo<Object> responseInfo) {

                    JSONObject jb = new JSONObject(responseInfo.result.toString());
                    fid = jb.optString("fid");

                    Log.i("i072", "file uploaded, return fid: "+fid);

                    if (!jb.s("fid").equals("")) {
                        Toast.makeText(i072Activity.this, "Upload success", Toast.LENGTH_LONG).show();
                    }
                }

                @Override
                public void onFailure(HttpException e, String s) {
                    Log.i("Test", s);
                    Toast.makeText(i072Activity.this, "Avatar upload failed", Toast.LENGTH_SHORT).show();
                }
            });
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
        intent.putExtra(MediaStore.EXTRA_OUTPUT, smallImageURI);

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
        intent.putExtra(MediaStore.EXTRA_OUTPUT, smallImageURI);
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
                Intent intent = new Intent("android.media.action.IMAGE_CAPTURE");
                intent.putExtra(MediaStore.EXTRA_OUTPUT, rawImageUri);

                startActivityForResult(intent, PHOTO_REQUEST_CAREMA);

                ivTemp =iv_personImage;
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

    private final Handler handler = new Handler() {

        public void handleMessage(Message msg) {

            TextView output = (TextView) findViewById(R.id.OUTPUT);

            if (msg.what == APIConnection.responseProperty) {

                JSONObject jo = (JSONObject) msg.obj;

                // on Project Toolbox, {"obj":"associate","act":"mock","to_login_name":"test2","data":{"obj":"test","act":"output1","data":"blah"}}
                if (jo.optString("obj").equals("test") && jo.optString("act").equals("output1")) {

                    output.setText(jo.optString("data"));

                } else if (jo.optString("obj").equals("person") && jo.optString("act").equals("update")) {

                    Toast.makeText(i072Activity.this, "update success", Toast.LENGTH_SHORT).show();

                    Intent intent=new Intent();
                    intent.putExtra("name",name.getEditableText().toString());
                    intent.putExtra("uri",String.valueOf(smallImageURI));
                    setResult(0x123, intent);
                    finish();
                }
            }

            if (msg.what == APIConnection.stateProperty) {

                if (APIConnection.state == APIConnection.States.IN_SESSION) {

                }
            }
        }
    };

    private void updateInfo() {

        JSONObject req = new JSONObject();

        req.xput("obj","person");
        req.xput("act","update");
        req.xput("person_id",pid);

        JSONObject update_data = new JSONObject();
        
        update_data.xput("headFid",fid);
        update_data.xput("name",name.getText().toString());
        update_data.xput("gender",selectSex());
        update_data.xput("phoneNo",phoneNo.getText().toString());
        update_data.xput("address",address.getText().toString());
        update_data.xput("work_experience",work_experience.getText().toString());
        update_data.xput("edu_experience",edu_experience.getText().toString());
        update_data.xput("payment",payment.getText().toString());
        update_data.xput("singnature", singnature.getText().toString());
        update_data.xput("province", provience.getText().toString().trim());
        update_data.xput("city", city.getText().toString().trim());
        
        req.xput("update_data", update_data);

        APIConnection.send(req);
    }
}
