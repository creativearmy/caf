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

  /**
   * . 文件夹路径
   */
  public static final String FILE_PATH = Environment.getExternalStorageDirectory().toString()
                                         + "/demo/image/";

  /**
   * @return intent .
   * @Title: selectPhoto
   * @Description: 相册获取图片
   * @author ys
   * @date 2015年5月26日 下午6:36:31
   */
  public static Intent selectPhoto() {
    Intent intent = new Intent(Intent.ACTION_PICK, null);
    intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*");
    return intent;
  }

  /**
   * @param uri 文件路径
   * @return intent .
   * @Title: takePicture
   * @Description: 照相
   * @author 博森
   * @date 2015年5月26日 下午6:36:55
   */
  public static Intent takePicture(Uri uri) {
    Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
    intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 1);
    return intent;
  }

  /**
   * @param uri     目标uri
   * @param cropUri 保存uri
   * @param aspectX 裁剪框的宽比例
   * @param aspectY 裁剪框的高比例
   * @param width   宽度
   * @param height  高度
   * @return intent .
   * @Title: cropPhoto
   * @Description: 裁剪图片
   * @author 博森
   * @date 2015年5月26日 下午6:37:26
   */
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

  /**
   * @param context 上下文
   * @param uri     文件路径
   * @return 位图 .
   * @Title: getBitmapByUri
   * @Description: 通过URI获得Bitmap
   * @author 博森
   * @date 2015年5月26日 下午6:38:56
   */
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

  /**
   * @param context 上下文
   * @return 文件流
   * @Title: getInputStreamByUri
   * @Description: .通过路径获取文件流
   * @author ys
   * @date 2015年3月18日 上午9:57:07
   */
  public static InputStream getInputStreamByUri(Context context, Uri uri) {
    try {
      return context.getContentResolver().openInputStream(uri);
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }

  /**
   * @return 临时uri .
   * @Title: getTempUri
   * @Description: 获得临时的URI
   * @author ys
   * @date 2015年5月26日 下午6:35:41
   */
  public static Uri getTempUri() {
    if (!SdUtil.hasSd()) {
     // T.showShort("请插入SD卡");
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

  /**
   * @param context    上下文
   * @param contentUri 目标uri
   * @return 文件路径 .
   * @Title: getPathFromUri
   * @Description: 通过URI获得文件路径
   * @author 博森
   * @date 2015年5月26日 下午6:34:57
   */
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

  /**
   * @param ctx 上下文
   * @param bm  位图
   * @return true | false .
   * @Title: saveBitmap
   * @Description: 保存图片到相册
   * @author 博森
   * @date 2015年5月26日 下午6:34:19
   */
  public static boolean saveBitmap(Context ctx, Bitmap bm) {
    if (!SdUtil.hasSd()) {
     // T.showShort("请插入SD卡");
      return false;
    }
    String title = String.valueOf(System.currentTimeMillis());
    MediaStore.Images.Media.insertImage(ctx.getContentResolver(), bm, title, "");
    ctx.sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED, Uri.parse("file://"
                                                                        + Environment
                                                                            .getExternalStorageDirectory())));

    return true;
  }


  //--------------图片压缩上传------------------------------------
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
//                    Log.i(TAG, "已经保存");
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
    if( baos.toByteArray().length / 1024>1024) {//判断如果图片大于1024,进行压缩避免在生成图片（BitmapFactory.decodeStream）时溢出
      baos.reset();//重置baos即清空baos
      image.compress(Bitmap.CompressFormat.JPEG, 50, baos);//这里压缩50%，把压缩后的数据存放到baos中
    }
    ByteArrayInputStream isBm = new ByteArrayInputStream(baos.toByteArray());
    BitmapFactory.Options newOpts = new BitmapFactory.Options();
    //开始读入图片，此时把options.inJustDecodeBounds 设回true了
    newOpts.inJustDecodeBounds = true;
    Bitmap bitmap = BitmapFactory.decodeStream(isBm, null, newOpts);
    newOpts.inJustDecodeBounds = false;
    int w = newOpts.outWidth;
    int h = newOpts.outHeight;
    //float hh = 800f;
    float ww = width;//这里设置高度为800f
    //缩放比。由于是固定比例缩放，只用高或者宽其中一个数据进行计算即可
    int be = 1;//be=1表示不缩放
    if (w > h && w > ww) {//如果宽度大的话根据宽度固定大小缩放
      be = (int) (newOpts.outWidth / ww);
    }
//    else if (w < h && h > hh) {//如果高度高的话根据宽度固定大小缩放
//      be = (int) (newOpts.outHeight / hh);
//    }
    if (be <= 0)
      be = 1;
    newOpts.inSampleSize = be;//设置缩放比例
    newOpts.inPreferredConfig = Bitmap.Config.RGB_565;//降低图片从ARGB888到RGB565

    isBm = new ByteArrayInputStream(baos.toByteArray());

    //重新读入图片，注意此时已经把options.inJustDecodeBounds 设回false了
    bitmap = BitmapFactory.decodeStream(isBm, null, newOpts);
    return compressImage(bitmap,maxSize);
  }

  private static Bitmap getBitmapFromUri(Context context,Uri uri)
  {
    try
    {
      // 读取uri所在的图片
      Bitmap bitmap = MediaStore.Images.Media.getBitmap(context.getContentResolver(), uri);
      return bitmap;
    }
    catch (Exception e)
    {
      Log.e("[Android]", e.getMessage());
      Log.e("[Android]", "目录为：" + uri);
      e.printStackTrace();
      return null;
    }
  }

  private static Bitmap compressImage(Bitmap image,int maxSize) {

    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    image.compress(Bitmap.CompressFormat.JPEG, 90, baos);//质量压缩方法，这里100表示不压缩，把压缩后的数据存放到baos中
    int options = 90;
    while ( baos.toByteArray().length>maxSize&&options>0) {    //循环判断如果压缩后图片是否大于100kb,大于继续压缩
      baos.reset();//重置baos即清空baos
      options -= 20;//每次都减少10
      image.compress(Bitmap.CompressFormat.JPEG, options, baos);//这里压缩options%，把压缩后的数据存放到baos中

    }
    ByteArrayInputStream isBm = new ByteArrayInputStream(baos.toByteArray());//把压缩后的数据baos存放到ByteArrayInputStream中
    Bitmap bitmap = BitmapFactory.decodeStream(isBm, null, null);//把ByteArrayInputStream数据生成图片
    return bitmap;
  }





}
