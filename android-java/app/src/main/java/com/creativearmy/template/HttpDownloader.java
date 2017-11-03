package com.creativearmy.template;

import android.os.Handler;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class HttpDownloader {

    private URL url = null;

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

            return fileUtils.write2LocalFromInput(path, fileName, inputStream, handler, fileSize);

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
}
