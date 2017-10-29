package com.creativearmy.template.i052;

/**
 * Created by 王杰 on 2015/12/22.
 */
public class ItemBody {
    /**
     * 头像
     */
    private String headImage;
    /**
     * 名字
     */
    private String Name;
    /**
     * 内容
     */
    private String message;

    /**
     * 日期
     */
    private String date;
    /**
     * 消息的数目
     */
    private Integer number;

    private String cid;

    private String id;
    private String last;
    private String title;
    private long ut;
    private long vt;
    private String xtype;
    private String fid;
    private int count;







    public Integer getNumber() {
        return number;
    }

    public void setNumber(Integer number) {
        this.number = number;
    }

    public String getHeadImage() {
        return headImage;
    }

    public void setHeadImage(String headImage) {
        this.headImage = headImage;
    }

    public String getName() {
        return Name;
    }

    public void setName(String name) {
        Name = name;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public ItemBody(String headImage, String name, String message, String date, Integer number) {
        this.headImage = headImage;
        Name = name;
        this.message = message;
        this.date = date;
        this.number = number;
    }

    public ItemBody(String cid, String id, String last, String title, long ut, long vt, String xtype,String fid,int count) {
        this.cid = cid;
        this.id = id;
        this.last = last;
        this.title = title;
        this.ut = ut;
        this.vt = vt;
        this.xtype = xtype;
        this.fid=fid;
        this.count=count;
    }

    public String getCid() {
        return cid;
    }

    public void setCid(String cid) {
        this.cid = cid;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getLast() {
        return last;
    }

    public void setLast(String last) {
        this.last = last;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public long getUt() {
        return ut;
    }

    public void setUt(long ut) {
        this.ut = ut;
    }

    public long getVt() {
        return vt;
    }

    public void setVt(long vt) {
        this.vt = vt;
    }

    public String getXtype() {
        return xtype;
    }

    public void setXtype(String xtype) {
        this.xtype = xtype;
    }

    public String getFid() {
        return fid;
    }

    public void setFid(String fid) {
        this.fid = fid;
    }

    public int getCount() {
        return count;
    }

    public void setCount(int count) {
        this.count = count;
    }
}
