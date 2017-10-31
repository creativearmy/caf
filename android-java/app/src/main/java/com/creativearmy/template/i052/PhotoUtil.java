package com.creativearmy.template.i052;

import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.v4.content.CursorLoader;
import android.util.Log;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import static java.util.Calendar.getInstance;

public class PhotoUtil {

  public static final String FILE_PATH = Environment.getExternalStorageDirectory().toString()
                                         + "/demo/image/";

  public static Intent selectPhoto() {
    Intent intent = new Intent(Intent.ACTION_PICK, null);
    intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*");
    return intent;
  }

  public static Intent takePicture(Uri uri) {
    Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
    intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 1);
    return intent;
  }

  public static Intent cropPhoto(Uri uri, Uri cropUri, int aspectX, int aspectY, int width,
                                 int height) {
    Intent intent = new Intent("com.android.camera.action.CROP");
    intent.setDataAndType(uri, "image/*");
    intent.putExtra("crop", "true");
    intent.putExtra("aspectX", aspectX);
    intent.putExtra("aspectY", aspectY);
    intent.putExtra("outputX", width);
    intent.putExtra("outputY", height);
    intent.putExtra("scale", true);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, cropUri);
    intent.putExtra("return-data", false);
    intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());
    intent.putExtra("noFaceDetection", true);
    return intent;
  }

  public static Bitmap getBitmapByUri(Context context, Uri uri) {
    Bitmap bitmap = null;
    try {
      bitmap = BitmapFactory.decodeStream(context.getContentResolver().openInputStream(uri));
    } catch (FileNotFoundException e) {
      e.printStackTrace();
      return null;
    }
    return bitmap;
  }

  public static InputStream getInputStreamByUri(Context context, Uri uri) {
    try {
      return context.getContentResolver().openInputStream(uri);
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }

  public static Uri getTempUri() {
    if (!SdUtil.hasSd()) {

      return null;
    }

    String fileName = System.currentTimeMillis() + ".jpg";
    File out = new File(FILE_PATH);
    if (!out.exists()) {
      out.mkdirs();
    }
    out = new File(FILE_PATH, fileName);
    return Uri.fromFile(out);
  }

  public static String getPathFromUri(Context context, Uri contentUri) {
    if (contentUri != null) {
      if (contentUri.getScheme().toString().compareTo("content") == 0) {
        String[] proj = {MediaStore.Images.Media.DATA};
        CursorLoader loader = new CursorLoader(context, contentUri, proj, null, null, null);
        Cursor cursor = loader.loadInBackground();
        int index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
        cursor.moveToFirst();
        return cursor.getString(index);
      } else if (contentUri.getScheme().toString().compareTo("file") == 0) {
        String fileName = contentUri.toString().replace("file://", "");
        return fileName;
      }
    }
    return null;
  }

  public static boolean saveBitmap(Context ctx, Bitmap bm) {
    if (!SdUtil.hasSd()) {

      return false;
    }
    String title = String.valueOf(System.currentTimeMillis());
    MediaStore.Images.Media.insertImage(ctx.getContentResolver(), bm, title, "");
    ctx.sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED, Uri.parse("file://"
                                                                        + Environment
                                                                            .getExternalStorageDirectory())));

    return true;
  }



  public static File saveImg(Context context,Bitmap b,int maxSize,int width){
    File f = new File(context.getCacheDir()+"/"+getInstance().getTimeInMillis()
            + ".jpg");
    if (f.exists()) {
      f.delete();
    }
    ;
    try {
      FileOutputStream out = new FileOutputStream(f);
      comp(b,maxSize,width).compress(Bitmap.CompressFormat.JPEG, 90, out);
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

  public static Bitmap setPicToView(Context context,Intent picdata) {
//        Bundle bundle = picdata.getExtras();
//        if (bundle != null) {
//            Bitmap photo = bundle.getParcelable("data");
//            return photo;
//        }
    return getBitmapFromUri(context,picdata.getData());
  }

  private static Bitmap comp(Bitmap image,int maxSize,int width) {

    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    image.compress(Bitmap.CompressFormat.JPEG, 100, baos);
    // FIXME
    if( baos.toByteArray().length / 1024>1024) {//
      baos.reset();//
      image.compress(Bitmap.CompressFormat.JPEG, 50, baos);//
    }
    ByteArrayInputStream isBm = new ByteArrayInputStream(baos.toByteArray());
    BitmapFactory.Options newOpts = new BitmapFactory.Options();

    newOpts.inJustDecodeBounds = true;
    Bitmap bitmap = BitmapFactory.decodeStream(isBm, null, newOpts);
    newOpts.inJustDecodeBounds = false;
    int w = newOpts.outWidth;
    int h = newOpts.outHeight;
    //float hh = 800f;
    float ww = width;//

    int be = 1;//
    if (w > h && w > ww) {//
      be = (int) (newOpts.outWidth / ww);
    }
//    else if (w < h && h > hh) {//
//      be = (int) (newOpts.outHeight / hh);
//    }
    if (be <= 0)
      be = 1;
    newOpts.inSampleSize = be;//
    newOpts.inPreferredConfig = Bitmap.Config.RGB_565;//

    isBm = new ByteArrayInputStream(baos.toByteArray());


    bitmap = BitmapFactory.decodeStream(isBm, null, newOpts);
    return compressImage(bitmap,maxSize);
  }

  private static Bitmap getBitmapFromUri(Context context,Uri uri)
  {
    try
    {

      Bitmap bitmap = MediaStore.Images.Media.getBitmap(context.getContentResolver(), uri);
      return bitmap;
    }
    catch (Exception e)
    {
      Log.e("[Android]", e.getMessage());
      Log.e("[Android]", "director:" + uri);
      e.printStackTrace();
      return null;
    }
  }

  private static Bitmap compressImage(Bitmap image,int maxSize) {

    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    image.compress(Bitmap.CompressFormat.JPEG, 90, baos);//
    int options = 90;
    while ( baos.toByteArray().length>maxSize&&options>0) {    //
      baos.reset();//
      options -= 20;//
      image.compress(Bitmap.CompressFormat.JPEG, options, baos);//

    }
    ByteArrayInputStream isBm = new ByteArrayInputStream(baos.toByteArray());//
    Bitmap bitmap = BitmapFactory.decodeStream(isBm, null, null);//
    return bitmap;
  }





}
