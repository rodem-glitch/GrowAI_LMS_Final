package dao;

import malgnsoft.db.*;
import malgnsoft.util.Malgn;

public class UserSessionDao extends DataObject {

    private String type = "user";
    private int siteId = 0;
    private int userId = 0;
    
    public UserSessionDao() {
        this.table = "TB_USER_SESSION";
        this.PK = "user_id,session_type";
    }

    public void setSiteId(int sid) {
    this.siteId = sid;
}
    
    public void setUserId(int uid) {
        this.userId = uid;
    }
    
    public void setType(String type) {
        this.type = type;
    }

    public void setSession(String sessionId) {
        if(this.userId == 0 || this.siteId == 0 || "".equals(sessionId)) return;
        
        this.item("user_id", this.userId);
        this.item("site_id", this.siteId);
        this.item("session_type", this.type);
        this.item("session_id", sessionId);
        this.item("mod_date", Malgn.time("yyyyMMddHHmmss"));
        if(0 < this.findCount("user_id = " + this.userId + " AND session_type = '" + this.type + "'")) {
            this.update("user_id = " + this.userId + " AND session_type = '" + this.type + "'");
        } else {
            this.insert();
        }
    }

    public boolean isValid(String sid, int userId) {
        if(userId == 0 || "".equals(sid)) return false;
        return 0 < this.findCount("session_id = '" + sid + "' AND user_id = " + userId + " AND session_type = '" + this.type + "'");
    }
    
}