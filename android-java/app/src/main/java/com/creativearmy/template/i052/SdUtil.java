package com.creativearmy.template.i052;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.DecimalFormat;

/**
 * @author 博森
 * @ClassName: SdCardUtil
 * @Description: sd卡操作
 * @date 2015年5月26日 下午6:02:48
 */
public class SdUtil {

  /**
   * . SD卡根路径
   */
  private static final String SD_ROOT_PATH = Environment.getExternalStorageDirectory()
                                             + File.separator;

  /**
   * @return 存在，返回true，不存在，返回false .
   * @Title: hasSd
   * @Description: 测是否存在SD卡
   * @author 博森
   * @date 2015年5月26日 下午6:03:12
   */
  public static boolean hasSd() {
    return Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);
  }

  /**
   * @return 跟路径字符串 .
   * @Title: getRootPath
   * @Description: 获得sd卡根路径
   * @author 博森
   * @date 2015年5月26日 下午6:04:06
   */
  public static String getRootPath() {
    return SD_ROOT_PATH;
  }


  /**
   * @param filePathNoContainRoot 不含根路径的文件路径
   * @return true | false .
   * @Title: isFileExists
   * @Description: SD上某文件是否存在
   * @author 博森
   * @date 2015年5月26日 下午6:04:35
   */
  public static boolean isFileExists(String filePathNoContainRoot) {
    File file = new File(SD_ROOT_PATH + filePathNoContainRoot);
    return file.exists();
  }

  /**
   * . 创建文件
   *
   * @param folderNama .
   * @param fileName   .
   */
  public static File createFile(String folderNama, String fileName) {
    File file = new File(SD_ROOT_PATH + folderNama + File.separator + fileName);
    File fileFolder = new File(SD_ROOT_PATH + folderNama);
    // 如果文件夾不存在
    if (!fileFolder.exists()) {
      fileFolder.mkdirs();
    }

    // 这里不做文件是否存在的判�?
    try {
      if (file.createNewFile()) {
        return file;
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return null;
  }

  /**
   * . 在SD卡上创建文件�?,如果存在就不继续创建
   *
   * @param folderName .
   */
  public static void createFolderIfNoExist(String folderName) {
    File filefoder = new File(SD_ROOT_PATH + folderName);
    if (!filefoder.exists()) {
      filefoder.mkdirs();
    }
  }

  /**
   * . 删除SD卡上文件
   *
   * @param filePathNoContainRoot 文件路径
   */
  public static void deleteFile(String filePathNoContainRoot) {
    File file = new File(SD_ROOT_PATH + filePathNoContainRoot);
    // 不需要判断文件是否存�?
    file.delete();
  }

  /**
   * . 删除文件�?
   *
   * @param folderPath 文件夹的路径
   */
  public static void deleteFolder(String folderPath) {
    delAllFile(folderPath);
    String filePath = folderPath;
    filePath = filePath.toString();
    File myFilePath = new File(filePath);
    myFilePath.delete();
  }

  /**
   * . 删除文件
   *
   * @param path 文件的路�?
   */
  public static void delAllFile(String path) {
    File file = new File(path);
    if (!file.exists()) {
      return;
    }
    if (!file.isDirectory()) {
      return;
    }
    String[] tempList = file.list();
    File temp = null;
    for (int i = 0; i < tempList.length; i++) {
      if (path.endsWith(File.separator)) {
        temp = new File(path + tempList[i]);
      } else {
        temp = new File(path + File.separator + tempList[i]);
      }
      if (temp.isFile()) {
        temp.delete();
      }
      if (temp.isDirectory()) {
        delAllFile(path + "/" + tempList[i]);
        deleteFolder(path + "/" + tempList[i]);
      }
    }
  }

  /**
   * . 获取文件的Uri
   *
   * @param path 文件的路�? .
   * @return .
   */
  public static Uri getUriFromFile(String path) {
    File file = new File(path);
    return Uri.fromFile(file);
  }

  /**
   * . 获取指定文件大小
   *
   * @param file .
   * @return .
   * @throws Exception .
   */
  public static long getFileSize(File file) throws Exception {
    long size = 0;
    if (file.exists()) {
      FileInputStream fis = null;
      fis = new FileInputStream(file);
      size = fis.available();
      fis.close();
    } else {
      file.createNewFile();
    }
    return size;
  }

  /**
   * . 获取指定文件�?
   *
   * @param file .
   * @return .
   * @throws Exception .
   */
  public static long getFileSizes(File file) throws Exception {
    long size = 0;
    File[] flist = file.listFiles();
    for (int i = 0; i < flist.length; i++) {
      if (flist[i].isDirectory()) {
        size = size + getFileSizes(flist[i]);
      } else {
        size = size + getFileSize(flist[i]);
      }
    }
    return size;
  }

  /**
   * . 换算文件大小
   *
   * @param size .
   * @return .
   */
  public static String formatFileSize(long size) {
    DecimalFormat df = new DecimalFormat("#.00");
    String fileSizeString = "未知大小";
    if (size == 0) {
      fileSizeString = "0B";
    } else if (size < 1024) {
      fileSizeString = df.format((double) size) + "B";
    } else if (size < 1048576) {
      fileSizeString = df.format((double) size / 1024) + "K";
    } else if (size < 1073741824) {
      fileSizeString = df.format((double) size / 1048576) + "M";
    } else {
      fileSizeString = df.format((double) size / 1073741824) + "G";
    }
    return fileSizeString;
  }

  /**
   * . 获取目录大小
   *
   * @param path .
   * @return .
   */
  public static String getDirectorySize(String path) {
    File file = new File(path);
    try {
      return formatFileSize(getFileSizes(file));
    } catch (Exception e) {
      e.printStackTrace();
    }
    return "0B";
  }

  /**
   * .写图片文�? 在Android系统中，文件保存�? /data/data/PACKAGE_NAME/files 目录�?
   *
   * @throws IOException .
   */
  public static void saveImage(Context context, String fileName, Bitmap bitmap) throws IOException {
    saveImage(context, fileName, bitmap, 100);
  }

  /**
   * .保存
   *
   * @param context  .
   * @param fileName .
   * @param bitmap   .
   * @param quality  .
   * @throws IOException .
   */
  public static void saveImage(Context context, String fileName, Bitmap bitmap, int quality)
      throws IOException {
    if (bitmap == null || fileName == null || context == null) {
      return;
    }

    FileOutputStream fos = context.openFileOutput(fileName, Context.MODE_PRIVATE);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    bitmap.compress(CompressFormat.JPEG, quality, stream);
    byte[] bytes = stream.toByteArray();
    fos.write(bytes);
    fos.close();
  }

  /**
   * . 获取bitmap
   *
   * @param context  .
   * @param fileName .
   * @return .
   */
  public static Bitmap getBitmap(Context context, String fileName) {
    FileInputStream fis = null;
    Bitmap bitmap = null;
    try {
      fis = context.openFileInput(fileName);
      bitmap = BitmapFactory.decodeStream(fis);
    } catch (FileNotFoundException e) {
      e.printStackTrace();
    } catch (OutOfMemoryError e) {
      e.printStackTrace();
    } finally {
      try {
        fis.close();
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
    return bitmap;
  }

  /**
   * . 获取bitmap
   *
   * @param filePath .
   * @return .
   */
  public static Bitmap getBitmapByPath(String filePath) {
    return getBitmapByPath(filePath, null);
  }

  /**
   * . 通告文件路径获取文件
   *
   * @param filePath .
   * @param opts     .
   * @return .
   */
  public static Bitmap getBitmapByPath(String filePath, BitmapFactory.Options opts) {
    FileInputStream fis = null;
    Bitmap bitmap = null;
    try {
      File file = new File(filePath);
      if (file.exists()) {
        fis = new FileInputStream(file);
        bitmap = BitmapFactory.decodeStream(fis, null, opts);
      }
    } catch (FileNotFoundException e) {
      e.printStackTrace();
    } catch (OutOfMemoryError e) {
      e.printStackTrace();
    } finally {
      try {
        fis.close();
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
    return bitmap;
  }

  /**
   * . 获取bitmap
   *
   * @param file .
   * @return .
   */
  /**
   * @param file 文件
   * @return 位图 .
   * @Title: getBitmapByFile
   * @Description: 获取bitmap
   * @author 博森
   * @date 2015年5月26日 下午6:46:43
   */
  public static Bitmap getBitmapByFile(File file) {
    FileInputStream fis = null;
    Bitmap bitmap = null;
    try {
      fis = new FileInputStream(file);
      bitmap = BitmapFactory.decodeStream(fis);
    } catch (FileNotFoundException e) {
      e.printStackTrace();
    } catch (OutOfMemoryError e) {
      e.printStackTrace();
    } finally {
      try {
        fis.close();
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
    return bitmap;
  }

}
