package com.coscx.flt_im_plugin;

import com.beetle.bauhinia.db.IMessage;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.util.ArrayList;

/**
 * Created by houxh on 15/3/9.
 */
public class Conversation {
    public static final int CONVERSATION_PEER = 1;
    public static final int CONVERSATION_GROUP = 2;
    public static final int CONVERSATION_CUSTOMER_SERVICE = 3;
    public static final int CONVERSATION_PEER_SECRET = 4;//点对点加密会话

    public static final int STATE_UNINITIALIZE = 0;//未初始化状态
    public static final int STATE_WAIT = 1;//等待对方上线
    public static final int STATE_EXCHANGE = 2;//交换密钥中,暂时未被使用
    public static final int STATE_CONNECTED = 3;//连接成功，可以发送加密消息

    public long rowid;
    public int type;
    public long appid;
    public long cid;
    public int state;//p2p加密会话的状态,普通会话此字段无意义
    public IMessage message;

    //search
    public ArrayList<IMessage> messages = new ArrayList<>();

    private String name;

    public String getAttrs() {
        return attrs;
    }

    public void setAttrs(String attrs) {
        this.attrs = attrs;
    }

    public int getFlags() {
        return flags;
    }

    public void setFlags(int flags) {
        this.flags = flags;
    }

    public int getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(int timestamp) {
        this.timestamp = timestamp;
    }

    private String attrs;
    private int flags;
    private int timestamp;
    private String avatar;
    private String detail;
    private int unreadCount;

    private PropertyChangeSupport changeSupport = new PropertyChangeSupport(
            this);

    public void addPropertyChangeListener(PropertyChangeListener listener) {
        changeSupport.addPropertyChangeListener(listener);
    }

    public void removePropertyChangeListener(PropertyChangeListener listener) {
        changeSupport.removePropertyChangeListener(listener);
    }

    public void addPropertyChangeListener(String propertyName,
                                          PropertyChangeListener listener) {
        changeSupport.addPropertyChangeListener(propertyName, listener);
    }


    public void setName(String name) {
        String old = this.name;
        this.name = name;
        changeSupport.firePropertyChange("name", old, this.name);
    }

    public String getName() {
        return this.name;
    }

    public void setAvatar(String avatar) {
        String old = this.avatar;
        this.avatar = avatar;
        changeSupport.firePropertyChange("avatar", old, this.avatar);
    }

    public String getAvatar() {
        return this.avatar;
    }

    public void setDetail(String detail) {
        String old = this.detail;
        this.detail = detail;
        changeSupport.firePropertyChange("detail", old, this.detail);
    }

    public String getDetail() {
        return this.detail;
    }

    public void setUnreadCount(int unreadCount) {
        int old = this.unreadCount;
        this.unreadCount = unreadCount;
        changeSupport.firePropertyChange("unreadCount", old, this.unreadCount);
    }

    public int getUnreadCount() {
        return this.unreadCount;
    }
}
