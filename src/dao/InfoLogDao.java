package dao;

import java.util.concurrent.ConcurrentHashMap;
import malgnsoft.db.*;
import malgnsoft.util.*;

public class InfoLogDao extends DataObject {

    public String[] types = {"A=>동의", "L=>목록", "V=>조회", "E=>엑셀", "C=>등록", "U=>갱신"};
    public String[] categories = { "B=>관리자단", "T=>교강사단" };

    private static final ConcurrentHashMap<Integer, String> LAST_PURGE_DATE_BY_SITE = new ConcurrentHashMap<>();

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

        // 왜: 개인정보 조회 로그를 3년까지만 보관해야 하므로, 조회 시점에 오래된 로그를 정리합니다.
        this.purgeExpiredLogs();

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

    public void purgeExpiredLogs() {
        if(this.siteId == 0) return;

        String today = Malgn.time("yyyyMMdd");
        String lastPurgeDate = LAST_PURGE_DATE_BY_SITE.get(this.siteId);
        if(today.equals(lastPurgeDate)) return;

        // 왜: 하루 1회만 정리하여 불필요한 반복 삭제를 막습니다.
        LAST_PURGE_DATE_BY_SITE.put(this.siteId, today);

        String now = Malgn.time("yyyyMMddHHmmss");
        String cutoff = Malgn.addDate("M", -36, now, "yyyyMMddHHmmss");

        // 왜: 연결 테이블을 먼저 지워야 로그 삭제 후에도 고아 데이터가 남지 않습니다.
        this.execute(
            "DELETE FROM TB_INFO_USER "
            + " WHERE site_id = " + this.siteId
            + " AND log_id IN ("
            + " SELECT id FROM " + this.table
            + " WHERE site_id = " + this.siteId
            + " AND reg_date < '" + cutoff + "'"
            + " )"
        );

        // 왜: 3년이 지난 개인정보 조회 로그를 정리하여 보관 기간을 지킵니다.
        this.execute(
            "DELETE FROM " + this.table
            + " WHERE site_id = " + this.siteId
            + " AND reg_date < '" + cutoff + "'"
        );
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
