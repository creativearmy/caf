package com.creativearmy.template.i052;

/**
 * Created by Administrator on 2016/3/23 0023.
 */

import android.os.Handler;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class HttpDownloader {

    private URL url = null;

    /**
     * @param urlStr
     * @param path
     * @param fileName
     * @return -1:文件下载出错
     * 0:文件下载成功
     * 1:文件已经存在
     */

    public File downFile(String urlStr, String path, String fileName){
      return  downFile( urlStr,  path,  fileName,null);
    }

    public File downFile(String urlStr, String path, String fileName, Handler handler) {
        InputStream inputStream = null;
        try {
            FileUtils fileUtils = new FileUtils();
            HttpURLConnection urlConn;
            url = new URL(urlStr);
            urlConn = (HttpURLConnection) url.openConnection();
            urlConn.setRequestProperty("Accept-Encoding", "identity");
            inputStream = urlConn.getInputStream();
            long fileSize =urlConn.getContentLength();
            return fileUtils.write2LocalFromInput(path, fileName, inputStream, handler,fileSize);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                inputStream.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * 根据URL得到输入流
     *
     * @param urlStr
     * @return
     */
    /*private InputStream getInputStreamFromURL(String urlStr) {
        HttpURLConnection urlConn;
        InputStream inputStream = null;
        try {
            url = new URL(urlStr);
            urlConn = (HttpURLConnection) url.openConnection();
            urlConn .setRequestProperty("Accept-Encoding", "identity");
            inputStream = urlConn.getInputStream();
            Log.v("zmh","文件大小："+urlConn.getContentLength());
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return inputStream;
    }*/
}
