package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class WebtvRecommDao extends DataObject {

	private int siteId = 0;

	public WebtvRecommDao() {
		this.table = "LM_WEBTV_RECOMM";
		this.PK = "webtv_id,user_id";
	}

	public WebtvRecommDao(int siteId) {
		this.table = "LM_WEBTV_RECOMM";
		this.PK = "webtv_id,user_id";
		this.siteId = siteId;
	}

	public boolean recomm(int userId, int webtvId) {
		if(findCount("webtv_id = " + webtvId + " AND user_id = " + userId) == 0) {
			this.item("webtv_id", webtvId);
			this.item("user_id", userId);
			this.item("site_id", siteId);
			this.item("reg_date", Malgn.getTimeString("yyyyMMddHHmmss"));
			return this.insert();
		}
		return false;
	}

	public boolean removeRecomm(int userId, int webtvId) {
		return delete("webtv_id = " + webtvId + " AND user_id = " + userId);
	}

}