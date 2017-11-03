package com.creativearmy.template;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.v4.widget.SwipeRefreshLayout;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.view.View.OnLayoutChangeListener;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.AbsListView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TableLayout;
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

import com.creativearmy.template.i052.*;

import org.json.JSONException;

import java.io.File;
import java.util.ArrayList;
import com.creativearmy.sdk.JSONObject;

public class i052Chatactivity extends Activity implements OnLayoutChangeListener, SwipeRefreshLayout.OnRefreshListener, SizeNotifierRelativeLayout.SizeNotifierRelativeLayoutDelegate, View.OnClickListener, TextWatcher {
    MessAdapter mMessAdapter;
    SwipeRefreshLayout mSwipeView;
    Button mBtnSendMsg;
    ImageButton mBtnAddFile;
    EditText mEditChatInput;
    TableLayout mMoreMenuTl;
    ImageView mBtnBack;
    LinearLayout mLinearChat;
    TextView mTvTitle;
    private boolean mIsShowMoreMenu = false;
    private String mNextId;

    private String mode = "chat";
    public  String Title;

    public static String mTopicId;

    public static String mTaskId;

    public static String mPersonId;

    private ImageView imgPhoto;
    private ImageView imgCamera;
    private static int REQUEST_PHOTO = 1;
    private static int REQUEST_CAMERA = 2;
    private static int PHOTO_REQUEST_CUT_CIRCLE = 3;
    private Uri tempUri;

    private Uri imageUri;

    private int imageMaxWidth;
    private int imageMaxSize;

    private ListView msgListview;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);


        mKeyboradHeigth = getisKeyboardHeight();
        APIConnection.registerHandler(handler);

        findViewById(R.id.relative_activity_chat).addOnLayoutChangeListener(this);
        mLinearChat = (LinearLayout) findViewById(R.id.send_msg_layout);
        mSwipeView = (SwipeRefreshLayout) findViewById(R.id.chat_refresh);
        mSwipeView.setEnabled(false);
        mBtnAddFile = (ImageButton) findViewById(R.id.add_file_btn);
        mBtnBack = (ImageView) findViewById(R.id.i040_back);
        mBtnSendMsg = (Button) findViewById(R.id.send_msg_btn);
        mEditChatInput = (EditText) findViewById(R.id.chat_input_et);
        mMoreMenuTl = (TableLayout) findViewById(R.id.more_menu_tl);
        mTvTitle = (TextView) findViewById(R.id.tv_bar_title);
        mBtnAddFile.setOnClickListener(this);
        mBtnSendMsg.setOnClickListener(this);
        mEditChatInput.addTextChangedListener(this);
        mEditChatInput.setOnFocusChangeListener(new android.view.View.
                OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                if (hasFocus) {

                    i052Chatactivity.this.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
                } else {

                }
            }
        });
        mBtnBack.setOnClickListener(this);
        imgPhoto = (ImageView) findViewById(R.id.img_photo);
        imgPhoto.setOnClickListener(this);
        imgCamera = (ImageView) findViewById(R.id.img_camera);
        imgCamera.setOnClickListener(this);
        msgListview = (ListView) findViewById(R.id.chat_list);
        mMessAdapter = new MessAdapter(this);
        msgListview.setAdapter(mMessAdapter);

        mode = "chat";

        mPersonId = "o14509039359136660099";

        Title = "personal chat: i052Chatactivity.java mPersonId";

        mTvTitle.setText(Title);
        mTvTitle.setTextColor(Color.WHITE);

        JSONObject req = new JSONObject();

        if (mode.equals("chat")) {
            req.xput("obj", "message");
            req.xput("act", "chat_get");
		
            JSONArray ja = new JSONArray();

            ja.put(APIConnection.user_info.optString("_id"));
            ja.put(mPersonId);

            req.xput("users", ja);
        }

        req.xput("person_id", APIConnection.user_info.optString("_id"));
        Log.e("I052", String.format("PID = %s\tTID = %s", "", mTopicId));
        APIConnection.send(req);

        mSwipeView.setOnRefreshListener(this);


        msgListview.setOnScrollListener(new AbsListView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(AbsListView absListView, int i) {

            }

            @Override
            public void onScroll(AbsListView absListView, int firstVisibleItem, int visibleItemCount, int totalItemCount) {
                if (firstVisibleItem == 0)
                    mSwipeView.setEnabled(true);
                else
                    mSwipeView.setEnabled(false);
            }
        });

        imageMaxWidth = Integer.parseInt(getImageWidth());
        imageMaxSize = Integer.parseInt(getImageSize());

    }

    public String getImageWidth() {
        if (APIConnection.server_info == null ||
                APIConnection.server_info.optString("resize_upload_im_image_width_to").equals("")) return 800+"";

        return APIConnection.server_info.optString("resize_upload_im_image_width_to");
    }
    public String getImageSize() {
        if (APIConnection.server_info == null ||
                APIConnection.server_info.optString("compress_upload_im_image_max").equals("")) return 100000+"";

        return APIConnection.server_info.optString("compress_upload_im_image_max");
    }

    private boolean isfollowing = false;
    private final Handler handler = new Handler() {
        public void handleMessage(Message msg) {
            if (msg.what == APIConnection.responseProperty) {
                JSONObject jo = (JSONObject) msg.obj;
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


                if ((jo.optString("obj").equals("topic") || jo.optString("obj").equals("task"))
  		            && jo.optString("act").equals("chat_get")) {

                    isfollowing = jo.optInt("following") == 0 ? false : true;

                    if (null != jo.optJSONObject("chatRecord"))
                    {
                        JSONObject object =jo.optJSONObject("chatRecord");
                        mNextId = object.optString("next_id");

                        if(null != object.optJSONArray("records"))
                        {
                            JSONArray array =object.optJSONArray("records");
                            ArrayList<JSONObject> listMsges = new ArrayList<JSONObject>();
                            generateData(array, listMsges);

                            // for initial read, scroll to the bottom of the list view
                            boolean initial_read = (mMessAdapter.getCount() == 0);

                            if (null != mMessAdapter) {
                                if (array.length()==1){
                                    mMessAdapter.addNetMessage(listMsges);
                                }else{
                                    mMessAdapter.addHistory(listMsges);
                                }
                            }

                            if (initial_read) {
                                msgListview.setSelection(mMessAdapter.getCount() - 1);
                            }
                        }
                    }
                }

                if (jo.optString("obj").equals("person") && jo.optString("act").equals("chat_get"))
                {
                        JSONObject object =jo.optJSONObject("chatRecord");
                        mNextId = object.optString("next_id");

                        if(null != object.optJSONArray("records"))
                        {
                            JSONArray array =object.optJSONArray("records");
                            ArrayList<JSONObject> listMsges = new ArrayList<JSONObject>();
                            generateData(array, listMsges);

                            // for initial read, scroll to the bottom of the list view
                            boolean initial_read = (mMessAdapter.getCount() == 0);

                            if (null != mMessAdapter) {
                                if (array.length()==1){
                                    mMessAdapter.addNetMessage(listMsges);
                                }else{
                                    mMessAdapter.addHistory(listMsges);
                                }
                            }

                            if (initial_read) {
                                msgListview.setSelection(mMessAdapter.getCount() - 1);
                            }
			}
                }

                if (jo.optString("obj").equals("push") && 
                    (   jo.optString("act").equals("chat_topic") && mode.equals("topic") && jo.optString("topic_id").equals(mTopicId)
                     || jo.optString("act").equals("chat_task") && mode.equals("task") && jo.optString("task_id").equals(mTaskId)
                     || jo.optString("act").equals("chat_person") && mode.equals("person") && jo.optString("from_id").equals(mPersonId)
                    )) {

                    ArrayList<JSONObject> listMsges = new ArrayList<JSONObject>();

                    String from_name = jo.optString("from_name");
                    int send_time = jo.optInt("chat_time");
                    String from_id = jo.optString("from_id");
                    String from_image = jo.optString("from_image");
//                            String state = jo.optString("topic_id");
                    String xtype = jo.optString("chat_type");

                    JSONObject netMessage1 = new JSONObject();
                    try {
                        if (from_id.equals(APIConnection.user_info.optString("_id"))) {//
                            netMessage1.put("type_tran", "SEND");
                        } else {
                            netMessage1.put("type_tran", "RECV");
                        }

                        if (xtype.equals("ximage")) {
                            netMessage1.put("content", jo.o("chat_content"));
                        } else {
                            netMessage1.put("content", jo.s("chat_content"));
                        }

                        netMessage1.put("from_name", from_name);
                        netMessage1.put("from_id", from_id);
                        netMessage1.put("from_image", from_image);
                        netMessage1.put("send_time", send_time);
                        netMessage1.put("xtype", xtype);
                        listMsges.add(netMessage1);
                    } catch (Exception e) {}

                    if (null != mMessAdapter) {
                        mMessAdapter.addNetMessage(listMsges);
                    }
                } else if ((jo.optString("obj").equals("topic") || jo.optString("obj").equals("task")) && jo.optString("act").equals("follow")) {
                    ToastUtil.showShortToast(i052Chatactivity.this, "Follow success");

                    isfollowing = !isfollowing;
                }

                if (jo.optString("obj").equals("message")
		    && jo.optString("act").equals("chat_send") ) {
                }


            }
        }
    };

    private void generateData(JSONArray array, ArrayList<JSONObject> listMsges) {
        for (int i = 0; i < array.length(); i++) {
            JSONObject jo = array.optJSONObject(i);

            String xtype = array.optJSONObject(i).optString("xtype");

            JSONObject netMessage1 = new JSONObject();
            try {
                if (jo.s("from_id").equals(APIConnection.user_info.optString("_id"))) {
                    netMessage1.put("type_tran", "SEND");
                } else {
                    netMessage1.put("type_tran", "RECV");
                }

                if (xtype.equals("ximage")) {
                    netMessage1.put("content", jo.o("content"));
                } else {
                    netMessage1.put("content", jo.s("content"));
                }

                netMessage1.put("from_name", jo.s("from_name"));
                netMessage1.put("from_id", jo.s("from_id"));
                netMessage1.put("from_image", jo.s("from_image"));
                netMessage1.put("send_time", jo.i("send_time"));
                netMessage1.put("xtype", xtype);

                listMsges.add(netMessage1);
            } catch (Exception e) {}
        }
    }

    @Override
    public void onRefresh() {
        mSwipeView.setRefreshing(true);
        (new Handler()).postDelayed(new Runnable() {
            @Override
            public void run() {
                mSwipeView.setRefreshing(false);

                if (null == mNextId || "".equals(mNextId) || "0".equals(mNextId)) return;

                JSONObject req = new JSONObject();

                req.xput("obj", "message");

                if (mode.equals("chat")) {
                    req.xput("act", "chat_get");
                }

                req.xput("block_id", mNextId);

                APIConnection.send(req);
            }
        }, 1500);
    }

    @Override
    public void onSizeChanged(int height) {
        Rect localRect = new Rect();
        getActivity().getWindow().getDecorView().getWindowVisibleDisplayFrame(localRect);

        WindowManager wm = (WindowManager) App.getInstance().getSystemService(Activity.WINDOW_SERVICE);
        if (wm == null || wm.getDefaultDisplay() == null) {
            return;
        }
    }

    private Activity getActivity() {
        return this;
    }


    private boolean isRemoveMoreMenu = false;

    private void setVisibilityMoreMenu(boolean isShow) {
        mIsShowMoreMenu = isShow;
        if (isShow) {
            setMoreMenuHeight();
            mMoreMenuTl.setVisibility(View.VISIBLE);
            if (isRemoveMoreMenu) {
                mLinearChat.addView(mMoreMenuTl);
                isRemoveMoreMenu = false;
            }
        } else {
            mLinearChat.removeView(mMoreMenuTl);
            isRemoveMoreMenu = true;
        }
    }

    private boolean isKeyboardShow = false;
    private int mKeyboradHeigth;
    private boolean mIsNeedshowTab = false;

    @Override
    public void onLayoutChange(View v, int left, int top, int right,
                               int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
        if (oldBottom != 0 && bottom != 0 && (oldBottom > bottom)) {
            isKeyboardShow = true;
            setVisibilityMoreMenu(false);
            mKeyboradHeigth = oldBottom - bottom;
        } else if (oldBottom != 0 && bottom != 0 && (bottom > oldBottom)) {
            isKeyboardShow = false;
            if (!mIsNeedshowTab) {
                setVisibilityMoreMenu(false);
            }
        }

    }

    @Override
    public void onClick(View view) {
        int id = view.getId();
        switch (id) {
            case R.id.add_file_btn:

                mIsNeedshowTab = !mIsNeedshowTab;
                if (mIsShowMoreMenu) {
                    if (!isKeyboardShow) {
                        focusToInput(true);
                        this.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
                    }
                } else {
                    setVisibilityMoreMenu(true);
                    if (isKeyboardShow) {
                        dismissSoftInput();
                        focusToInput(false);
                        this.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN);
                    }
                }
                break;
            case R.id.send_msg_btn:

                JSONObject req = new JSONObject();

                if (mode.equals("chat")) {
                    req.xput("obj", "message");
                    req.xput("act", "chat_send");
                    req.xput("to_id", mPersonId);

                }

                req.xput("from_id", APIConnection.user_info.optString("_id"));

                req.xput("chat_type", "text");
                req.xput("chat_content", mEditChatInput.getText().toString());
                APIConnection.send(req);

                JSONObject netMessage1 = new JSONObject();
                try {
                    netMessage1.put("type_tran", "SEND");
                    netMessage1.put("content", (mEditChatInput.getText().toString()));
                    netMessage1.put("send_time", ((int)(System.currentTimeMillis()/1000)));
                    netMessage1.put("xtype", "text");
                } catch (Exception e) {}

                if (null != mMessAdapter) {
                    mMessAdapter.addNetMessage(netMessage1);
                }
                mEditChatInput.setText("");
                break;
            case R.id.i040_back:
                finish();
                break;
            case R.id.img_photo:
                startActivityForResult(PhotoUtil.selectPhoto(), REQUEST_PHOTO);
                break;
            case R.id.img_camera:
                imageUri = PhotoUtil.getTempUri();
                startActivityForResult(PhotoUtil.takePicture(imageUri), REQUEST_CAMERA);
                break;

            default:
                break;
        }
    }

    private int getisKeyboardHeight() {
        SharedPreferences share = getSharedPreferences("keyboardheight", Activity.MODE_PRIVATE);
        return share.getInt("height", 1000);
    }

    private void saveKeyboardHeight(int height) {
        SharedPreferences sharedPreferences = getSharedPreferences("keyboardheight", Context.MODE_PRIVATE); //
        SharedPreferences.Editor editor = sharedPreferences.edit();//
        editor.putInt("height", height);
        editor.apply();//
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        saveKeyboardHeight(mKeyboradHeigth);
    }

    CharSequence temp = "";

    @Override
    public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

    }

    @Override
    public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        temp = charSequence;
    }

    @Override
    public void afterTextChanged(Editable editable) {
        if (temp.length() > 0) {
            mBtnAddFile.setVisibility(View.GONE);
            mBtnSendMsg.setVisibility(View.VISIBLE);
        } else {
            mBtnAddFile.setVisibility(View.VISIBLE);
            mBtnSendMsg.setVisibility(View.GONE);
        }
    }

    public void setMoreMenuHeight() {
        mMoreMenuTl.setLayoutParams(new LinearLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, mKeyboradHeigth));
    }

    public static int dip2px(Context context, float dpValue) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dpValue * scale + 0.5f);
    }


    private void showSoftInput() {
        if (this.getWindow().getAttributes().softInputMode == WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN) {
            if (this.getCurrentFocus() != null) {
                InputMethodManager imm = ((InputMethodManager) this.getSystemService(Activity.INPUT_METHOD_SERVICE));
                imm.showSoftInputFromInputMethod(this.getCurrentFocus().getWindowToken(), 0);
            }
        }
    }

    public void dismissSoftInput() {

        InputMethodManager imm = ((InputMethodManager) this.getSystemService(Activity.INPUT_METHOD_SERVICE));
        if (this.getWindow().getAttributes().softInputMode != WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN) {
            if (this.getCurrentFocus() != null)
//                imm.hideSoftInputFromWindow(mContext.getCurrentFocus().getWindowToken(),InputMethodManager.HIDE_NOT_ALWAYS);
                imm.hideSoftInputFromWindow(this.getCurrentFocus().getWindowToken(), InputMethodManager.HIDE_NOT_ALWAYS);
        }
    }

    public void focusToInput(boolean inputFocus) {
        if (inputFocus) {
            mEditChatInput.requestFocus();
            Log.i("ChatView", "show softInput");
            InputMethodManager imm = (InputMethodManager) this.getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.toggleSoftInput(0, InputMethodManager.HIDE_NOT_ALWAYS);
        } else {
            mBtnAddFile.requestFocusFromTouch();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == RESULT_OK &&requestCode == REQUEST_PHOTO) {
            if (data != null) {
                upLoadImg(data);
            }
        } else if (resultCode == RESULT_OK &&requestCode == REQUEST_CAMERA) {
            if(imageUri!=null) {
                data = new Intent();
                data.setData(imageUri);
                upLoadImg(data);
            }
        } else if (requestCode == PHOTO_REQUEST_CUT_CIRCLE) {
            upLoadImg(data);
        }
    }

    private void upLoadImg(Intent data) {
        Toast.makeText(i052Chatactivity.this, "upload", Toast.LENGTH_LONG).show();
        RequestParams rp = new RequestParams();
        if (data != null) {
            File f = null;
            f = PhotoUtil.saveImg(this,PhotoUtil.setPicToView(this,data),imageMaxSize,imageMaxWidth);


            Log.i("Test", "File is Not :" + (f.isFile() ? "yes" : "No"));
            rp.addBodyParameter("local_file", f);
            rp.addBodyParameter("proj", APIConnection.server_info.optString("proj"));
            HttpUtils h = new HttpUtils();

            h.send(HttpRequest.HttpMethod.POST, APIConnection.server_info.optString("upload_to"), rp, new RequestCallBack<Object>() {
                @Override
                public void onSuccess(ResponseInfo<Object> responseInfo) {
                    try {
                        JSONObject jb = new JSONObject(responseInfo.result.toString());

                        String fid = jb.s("fid");
                        String thumb = jb.s("thumb");
                        String mime = jb.s("type");

                        if (jb.optString("fid") != null && !jb.optString("fid").equals("")) {
                            Toast.makeText(i052Chatactivity.this, "upload succeeded", Toast.LENGTH_LONG).show();

                            JSONObject req = new JSONObject();

                            if (mode.equals("chat")) {
                                req.xput("obj", "message");
                                req.xput("act", "chat_send");
                                req.xput("topic_id", mTopicId);

                            }

                            JSONObject chat_content = new JSONObject();
                            chat_content.put("thumb", thumb);
                            chat_content.put("fid", fid);
                            chat_content.put("mime", mime);

                            req.xput("from_id", APIConnection.user_info.optString("_id"));
                            req.xput("chat_type", "ximage");
                            req.xput("chat_content", chat_content);
                            APIConnection.send(req);

                            JSONObject netMessage1 = new JSONObject();
                            netMessage1.put("type_tran", "SEND");
                            netMessage1.put("content", chat_content);
                            netMessage1.put("send_time", (int) (System.currentTimeMillis() / 1000));
                            netMessage1.put("xtype", "ximage");
                            if (null != mMessAdapter) {
                                mMessAdapter.addNetMessage(netMessage1);
                            }
                        }


                    } catch (JSONException e) {
                        e.printStackTrace();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void onFailure(HttpException e, String s) {
                    Log.i("Test", s);
                    Toast.makeText(i052Chatactivity.this, "upload failed", Toast.LENGTH_SHORT).show();
                }
            });
        }
    }


}
