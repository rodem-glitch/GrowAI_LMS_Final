package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class WebtvLogDao extends DataObject {

	private int siteId = 0;

	public WebtvLogDao() {
		this.table = "LM_WEBTV_LOG";
		this.PK = "id";
	}

	public WebtvLogDao(int siteId) {
		this.table = "LM_WEBTV_LOG";
		this.PK = "id";
		this.siteId = siteId;
	}

	public boolean log(int userId, int webtvId) {
		return this.log(userId, webtvId, 24);
	}

	public boolean log(int userId, int webtvId, int hour) {
		//시간체크
		if(1 > hour || 1 > findCount("webtv_id = " + webtvId + " AND user_id = " + userId + " AND reg_date >= '" + Malgn.addDate("H", -1 * hour, Malgn.time("yyyyMMddHHmmss"), "yyyyMMddHHmmss") + "'")) {
			this.item("id", this.getSequence());
			this.item("webtv_id", webtvId);
			this.item("user_id", userId);
			this.item("site_id", siteId);
			this.item("reg_date", Malgn.getTimeString("yyyyMMddHHmmss"));
			return this.insert();
		}
		return false;
	}

	public boolean removeLog(int userId, int webtvId) {
		return delete("webtv_id = " + webtvId + " AND user_id = " + userId);
	}

}