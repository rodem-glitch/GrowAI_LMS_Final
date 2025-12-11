package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class InfoLogDao extends DataObject {

    public String[] types = {"A=>동의", "L=>목록", "V=>조회", "E=>엑셀", "C=>등록", "U=>갱신"};
    public String[] categories = { "B=>관리자단", "T=>교강사단" };

    public int userId = 0;
    public int siteId = 0;
    public String logCate = "B";
    public String pagePath = "";
    public String ipAddr = "";
    public int exclusion = 1;

    public InfoLogDao() {
        this.table = "TB_INFO_LOG";
        this.PK = "id";
    }

    public InfoLogDao(int siteId) {
        this.table = "TB_INFO_LOG";
        this.PK = "id";
        this.siteId = siteId;
    }

    public void setItems(int userId, String cate, String path, String userIp) {
        this.userId = userId;
        this.logCate = cate;
        this.pagePath = path;
        this.ipAddr = userIp;
    }

    public int add(String logType, String pageNm, int userCnt, String purpose) {
        return this.add(logType, pageNm, userCnt, purpose, null);
    }

    public int add(String logType, String pageNm, int userCnt, String purpose, DataSet list) {
        if(this.userId == 0 || "".equals(this.pagePath) || "".equals(this.ipAddr)) return 0;

        String now = Malgn.time("yyyyMMddHHmmss");
        String today = Malgn.time("yyyyMMdd");
        String stdate = Malgn.addDate("I", -exclusion, now, "yyyyMMddHHmmss");
        InfoUserDao _logUser = new InfoUserDao(siteId); _logUser.setInsertIgnore(true);

        if(0 < this.findCount(
                "log_cate = '" + this.logCate + "' AND log_type = '" + logType + "' "
                        + " AND page_path = '" + this.pagePath + "' AND manager_id = " + this.userId + " "
                        + " AND ip_addr = '" + this.ipAddr + "' "
                        + " AND site_id = " + this.siteId
                        + " AND reg_date >= '" + stdate + "' "
        )) return -1;

        int newId = this.getSequence();

        this.item("id", newId);
        this.item("log_date", today);
        this.item("log_cate", this.logCate); //관리자
        this.item("log_type", logType); //동의
        this.item("page_nm", pageNm);
        this.item("page_path", this.pagePath);
        this.item("user_cnt", userCnt);
        this.item("purpose", purpose);
        this.item("memo", "");
        this.item("manager_id", this.userId);
        this.item("ip_addr", this.ipAddr);
        this.item("site_id", siteId);
        this.item("reg_date", now);
        this.item("status", 1);

        this.insert();
        if(newId > 0 && list != null) _logUser.add(newId, list);

        return newId;
    }

    public String getAgreeDate(int userId) {
        return this.getOne(
            "SELECT MAX(log_date) FROM " + this.table + " "
            + " WHERE manager_id = " + userId + " AND log_date = '" + Malgn.time("yyyyMMdd") + "' "
            + " AND log_cate = '" + this.logCate + "' AND log_type = 'A' "
            + " AND site_id =" + this.siteId
            + " AND status = 1 "
        );
    }

    public DataSet getManagers() {
        return this.query(
            "SELECT m.id user_id, m.user_nm, m.login_id, m.status "
            + " FROM TB_USER m "
            + " INNER JOIN ( "
            + " SELECT manager_id FROM " + this.table + " "
            + " WHERE status != -1 "
            + " AND site_id = " + this.siteId
            + " GROUP BY manager_id "
            + " ) a ON a.manager_id = m.id "
            + " WHERE m.status != -1 AND m.site_id = " + this.siteId
            + " ORDER BY m.id ASC "
        );
    }
}