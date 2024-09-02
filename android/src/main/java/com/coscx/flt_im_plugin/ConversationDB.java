package com.coscx.flt_im_plugin;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

public class ConversationDB {

    private static final String TAG = "goubuli";
    private static final String TABLE_NAME = "conversation";

    public static final String COLUMN_ROWID = "id";
    public static final String COLUMN_STATE = "state";
    public static final String COLUMN_UNREAD = "unread";


    private static ConversationDB instance = new ConversationDB();
    public static ConversationDB getInstance() {
        return instance;
    }

    private SQLiteDatabase mDB;

    public void setDb(SQLiteDatabase db) {
        this.mDB = db;
    }

    public SQLiteDatabase getDb() {
        return this.mDB;
    }

    public List<Conversation> getConversations() {
        ArrayList<Conversation> convs = new ArrayList<>();
        Cursor cursor = null;
        try {
            cursor = mDB.query(TABLE_NAME, new String[]{"id", "appid","target", "type", "name","attrs","flags","detail","state","timestamp","unread"},
                    null, null, null, null, null);
            while (cursor.moveToNext()) {
                long rowid = cursor.getLong(cursor.getColumnIndex("id"));
                long appid = cursor.getLong(cursor.getColumnIndex("appid"));
                long cid = cursor.getLong(cursor.getColumnIndex("target"));
                int type = cursor.getInt(cursor.getColumnIndex("type"));
                String name = cursor.getString(cursor.getColumnIndex("name"));
                String attrs = cursor.getString(cursor.getColumnIndex("attrs"));
                int flags = cursor.getInt(cursor.getColumnIndex("flags"));
                String detail = cursor.getString(cursor.getColumnIndex("detail"));
                int timestamp = cursor.getInt(cursor.getColumnIndex("timestamp"));
                int state = cursor.getInt(cursor.getColumnIndex("state"));
                int unread = cursor.getInt(cursor.getColumnIndex("unread"));
                Conversation conv = new Conversation();
                conv.rowid = rowid;
                conv.appid =appid;
                conv.cid = cid;
                conv.type = type;
                conv.state = state;
                conv.setAttrs(attrs);
                conv.setDetail(detail);
                conv.setFlags(flags);
                conv.setTimestamp(timestamp);
                conv.setUnreadCount(unread);
                conv.setName(name);
                convs.add(conv);
            }
        } catch (Exception ex) {
            Log.e("getConversations", ex.toString());
        } finally {
            if (null != cursor) {
                cursor.close();
            }
        }
        return convs;
    }
    public Conversation getConversation(long row_id) {
        Cursor cursor = null;
        try {

            cursor = mDB.query(TABLE_NAME, new String[]{"id", "appid","target", "type", "name","attrs","flags","detail","state","timestamp","unread"},
                    "id =? ",
                    new String[]{
                            String.valueOf(row_id),
                    },
                    null, null, null);
            if (cursor.moveToNext()) {
                long rowid = cursor.getLong(cursor.getColumnIndex("id"));
                long appid = cursor.getLong(cursor.getColumnIndex("appid"));
                long cid = cursor.getLong(cursor.getColumnIndex("target"));
                int type = cursor.getInt(cursor.getColumnIndex("type"));
                String name = cursor.getString(cursor.getColumnIndex("name"));
                String attrs = cursor.getString(cursor.getColumnIndex("attrs"));
                int flags = cursor.getInt(cursor.getColumnIndex("flags"));
                String detail = cursor.getString(cursor.getColumnIndex("detail"));
                int timestamp = cursor.getInt(cursor.getColumnIndex("timestamp"));
                int state = cursor.getInt(cursor.getColumnIndex("state"));
                int unread = cursor.getInt(cursor.getColumnIndex("unread"));
                Conversation conv = new Conversation();
                conv.rowid = rowid;
                conv.appid = appid;
                conv.cid = cid;
                conv.type = type;
                conv.state = state;
                conv.setAttrs(attrs);
                conv.setDetail(detail);
                conv.setFlags(flags);
                conv.setTimestamp(timestamp);
                conv.setUnreadCount(unread);
                conv.setName(name);
                return conv;
            }
        } catch (Exception ex) {
            Log.e("getConversation", ex.toString());
        } finally {
            if (null != cursor) {
                cursor.close();
            }
        }
        return null;
    }
    public Conversation getConversation(long appid,long cid, int type) {
        Cursor cursor = null;
        try {

            cursor = mDB.query(TABLE_NAME, new String[]{"id", "appid","target", "type", "name","attrs","flags","detail","state","timestamp","unread"},
                    "appid =? AND target=? AND type=?",
                    new String[]{
                            String.valueOf(appid),
                            String.valueOf(cid),
                            String.valueOf(type)
                    },
                    null, null, null);
            if (cursor.moveToNext()) {
                long rowid = cursor.getLong(cursor.getColumnIndex("id"));
                String name = cursor.getString(cursor.getColumnIndex("name"));
                String attrs = cursor.getString(cursor.getColumnIndex("attrs"));
                int flags = cursor.getInt(cursor.getColumnIndex("flags"));
                String detail = cursor.getString(cursor.getColumnIndex("detail"));
                int timestamp = cursor.getInt(cursor.getColumnIndex("timestamp"));
                int state = cursor.getInt(cursor.getColumnIndex("state"));
                int unread = cursor.getInt(cursor.getColumnIndex("unread"));
                Conversation conv = new Conversation();
                conv.rowid = rowid;
                conv.appid = appid;
                conv.cid = cid;
                conv.type = type;
                conv.state = state;
                conv.setAttrs(attrs);
                conv.setDetail(detail);
                conv.setFlags(flags);
                conv.setTimestamp(timestamp);
                conv.setUnreadCount(unread);
                conv.setName(name);
                return conv;
            }
        } catch (Exception ex) {
            Log.e("getConversation", ex.toString());
        } finally {
            if (null != cursor) {
                cursor.close();
            }
        }
        return null;
    }

    public boolean addConversation(Conversation conv) {
        boolean result = true;
        try {
            mDB.beginTransaction();
            ContentValues values = new ContentValues();
            values.put("appid", conv.appid);
            values.put("target", conv.cid);
            values.put("type", conv.type);
            values.put("name", conv.getName());
            values.put("attrs", conv.getAttrs());
            values.put("flags", conv.getFlags());
            values.put("detail", conv.getDetail());
            values.put("state", conv.state);
            values.put("timestamp", conv.getTimestamp());
            values.put("unread", conv.getUnreadCount());
            conv.rowid = mDB.insert(TABLE_NAME, null, values);
            values.clear();
            mDB.setTransactionSuccessful();
        } catch (Exception e) {
            e.printStackTrace();
            result = false;
        } finally {
            mDB.endTransaction();
        }
        return result;
    }

    public boolean setNewCount(long rowid, int count) {
        boolean result;
        try {

            ContentValues values = new ContentValues();
            values.put(COLUMN_UNREAD, count);

            int r = mDB.update(TABLE_NAME,
                    values, "id=?",
                    new String[] {
                            String.valueOf(rowid)
                    });

            result = r > 0;
        } catch (Exception e) {
            Log.e("setNewCount", e.toString());
            result = false;
        }
        return result;
    }


    public boolean setState(long rowid, int state) {
        boolean result;
        try {

            ContentValues values = new ContentValues();
            values.put(COLUMN_STATE, state);

            int r = mDB.update(TABLE_NAME,
                    values, "id=?",
                    new String[] {
                            String.valueOf(rowid)
                    });

            result = r > 0;
        } catch (Exception e) {
            Log.e("setState", e.toString());
            result = false;
        }
        return result;
    }

    public boolean resetState(int state) {
        boolean result = true;
        try {

            ContentValues values = new ContentValues();
            values.put(COLUMN_STATE, state);

            mDB.update(TABLE_NAME,
                    values, null,
                    null);

        } catch (Exception e) {
            Log.e("resetState", e.toString());
            result = false;
        }
        return result;
    }


    public boolean removeConversation(Conversation conv) {

        try {
            mDB.beginTransaction();

            mDB.delete(TABLE_NAME, "id=?",
                    new String[] {
                            String.valueOf(conv.rowid)
                    });
            mDB.setTransactionSuccessful();
        } catch (Exception e) {
            e.printStackTrace();
            if (mDB.inTransaction()) {
                mDB.endTransaction();
            }
            return false;
        } finally {
            if (mDB.inTransaction()) {
                mDB.endTransaction();
            }
        }
        return true;
    }
}
