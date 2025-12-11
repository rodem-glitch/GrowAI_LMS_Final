package dao;

import malgnsoft.db.*;

public class InfoUserDao extends DataObject {

    private int siteId = 0;

    public InfoUserDao() {
        this.table = "TB_INFO_USER";
        this.PK = "log_id,user_id";
    }

    public InfoUserDao(int siteId) {
        this.table = "TB_INFO_USER";
        this.PK = "log_id,user_id";
        this.siteId = siteId;
    }

    public void add(int logId, DataSet list) {
        if(logId > 0) {
            this.item("log_id", logId);
            this.item("site_id", siteId);
            list.first();
            while(list.next()) {
                int userId = list.i("user_id") > 0 ? list.i("user_id") : list.i("id");
                if(userId > 0) {
                    this.item("user_id", userId);
                    this.insert();
                }
            }
        }
    }

    public void add(int logId, int userId) {
        if(1 > logId || 1 > userId) return;
        this.item("log_id", logId);
        this.item("user_id", userId);
        this.item("site_id", siteId);
        this.insert();
    }
}