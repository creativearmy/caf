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

public class SdUtil {

  private static final String SD_ROOT_PATH = Environment.getExternalStorageDirectory()
                                             + File.separator;

  public static boolean hasSd() {
    return Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);
  }

  public static String getRootPath() {
    return SD_ROOT_PATH;
  }


  public static boolean isFileExists(String filePathNoContainRoot) {
    File file = new File(SD_ROOT_PATH + filePathNoContainRoot);
    return file.exists();
  }

  public static File createFile(String folderNama, String fileName) {
    File file = new File(SD_ROOT_PATH + folderNama + File.separator + fileName);
    File fileFolder = new File(SD_ROOT_PATH + folderNama);

    if (!fileFolder.exists()) {
      fileFolder.mkdirs();
    }


    try {
      if (file.createNewFile()) {
        return file;
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return null;
  }

  public static void createFolderIfNoExist(String folderName) {
    File filefoder = new File(SD_ROOT_PATH + folderName);
    if (!filefoder.exists()) {
      filefoder.mkdirs();
    }
  }

  public static void deleteFile(String filePathNoContainRoot) {
    File file = new File(SD_ROOT_PATH + filePathNoContainRoot);

    file.delete();
  }

  public static void deleteFolder(String folderPath) {
    delAllFile(folderPath);
    String filePath = folderPath;
    filePath = filePath.toString();
    File myFilePath = new File(filePath);
    myFilePath.delete();
  }

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

  public static Uri getUriFromFile(String path) {
    File file = new File(path);
    return Uri.fromFile(file);
  }

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

  public static String formatFileSize(long size) {
    DecimalFormat df = new DecimalFormat("#.00");
    String fileSizeString = "unkown";
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

  public static String getDirectorySize(String path) {
    File file = new File(path);
    try {
      return formatFileSize(getFileSizes(file));
    } catch (Exception e) {
      e.printStackTrace();
    }
    return "0B";
  }

  public static void saveImage(Context context, String fileName, Bitmap bitmap) throws IOException {
    saveImage(context, fileName, bitmap, 100);
  }

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

  public static Bitmap getBitmapByPath(String filePath) {
    return getBitmapByPath(filePath, null);
  }

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
