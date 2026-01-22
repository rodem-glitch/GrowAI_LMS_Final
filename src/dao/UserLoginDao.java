package dao;

import java.util.concurrent.ConcurrentHashMap;
import malgnsoft.db.*;
import malgnsoft.util.*;

public class UserLoginDao extends DataObject {

	public String[] adminYnList = { "N=>사용자단", "Y=>관리자단" };
	public String[] loginTypeList = { "I=>로그인", "O=>로그아웃", "S=>세션만료" };
	
	public String[] adminYnListMsg = { "N=>list.user_login.admin_yn_list.N", "Y=>list.user_login.admin_yn_list.Y" };
	public String[] loginTypeListMsg = { "I=>list.user_login.login_type_list.I", "O=>list.user_login.login_type_list.O", "S=>list.user_login.login_type_list.S" };

	private static final ConcurrentHashMap<Integer, String> LAST_PURGE_DATE_BY_SITE = new ConcurrentHashMap<>();
	
	public UserLoginDao() {
		this.table = "TB_USER_LOGIN";
	}

	public void purgeExpiredLogs(int siteId) {
		if(siteId == 0) return;

		String today = Malgn.time("yyyyMMdd");
		String lastPurgeDate = LAST_PURGE_DATE_BY_SITE.get(siteId);
		if(today.equals(lastPurgeDate)) return;

		// 왜: 하루 1회만 정리하여 불필요한 반복 삭제를 막습니다.
		LAST_PURGE_DATE_BY_SITE.put(siteId, today);

		String now = Malgn.time("yyyyMMddHHmmss");
		String cutoff = Malgn.addDate("Y", -2, now, "yyyyMMddHHmmss");

		// 왜: 접속 로그는 2년만 보관해야 하므로 오래된 로그를 정리합니다.
		this.execute(
			"DELETE FROM " + this.table
			+ " WHERE site_id = " + siteId
			+ " AND reg_date < '" + cutoff + "'"
		);
	}

	public boolean isMobile(String agent) {
		boolean isMobile = false;
		if(null != agent) {
			String[] mobileKeyWords = {
				"iPhone", "iPod", "iPad"
				, "BlackBerry", "Android", "Windows CE"
				, "LG", "MOT", "SAMSUNG", "SonyEricsson"
			};
			for(int i=0; i<mobileKeyWords.length; i++) {
				if(agent.indexOf(mobileKeyWords[i]) != -1) {
					isMobile = true;
					break;
				}
			}
		}
		return isMobile;
	}

	public String getDeviceType(String agent) {
		if(this.isMobile(agent)) return "Mobile";
		else return "PC";
	}
}
