package dao;

import malgnsoft.db.*;

public class TwowayLogDao extends DataObject {

    private int siteId = 0;

    public TwowayLogDao() {
        this.table = "LM_COURSE_USER_LOG";
        this.PK = "id";
    }

    public TwowayLogDao(int siteId) {
        this.table = "LM_COURSE_USER_LOG";
        this.PK = "id";
        this.siteId = siteId;
    }

    public void setSiteId(int siteId) {
        this.siteId = siteId;
    }
}