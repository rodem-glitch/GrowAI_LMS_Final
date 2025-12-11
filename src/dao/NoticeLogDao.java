package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class NoticeLogDao extends DataObject {

	private int siteId = 0;

	public NoticeLogDao() {
		this.table = "TB_NOTICE_LOG";
		this.PK = "user_id,notice_id,log_type";
	}

	public NoticeLogDao(int siteId) {
		this.table = "TB_NOTICE_LOG";
		this.PK = "user_id,notice_id,log_type";
		this.siteId = siteId;
	}

	public boolean log(int userId, int noticeId, String type) {
		if(findCount("notice_id = " + noticeId + " AND user_id = " + userId + " AND log_type = '" + type + "'") == 0) {
			this.item("notice_id", noticeId);
			this.item("user_id", userId);
			this.item("site_id", this.siteId);
			this.item("log_type", type);
			this.item("reg_date", Malgn.getTimeString("yyyyMMddHHmmss"));
			return this.insert();
		}
		return false;
	}

	public boolean removeLog(int userId, int noticeId, String type) {
		return delete("notice_id = " + noticeId + " AND user_id = " + userId + " AND log_type = '" + type + "'");
	}

	public boolean removeAllLog(int noticeId, String type) {
		return delete("notice_id = " + noticeId + " AND log_type = '" + type + "'");
	}

}