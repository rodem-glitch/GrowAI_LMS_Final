package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class PostLogDao extends DataObject {

	private int siteId = 0;

	public PostLogDao() {
		this.table = "TB_POST_LOG";
		this.PK = "user_id,post_id,log_type";
	}

	public PostLogDao(int siteId) {
		this.table = "TB_POST_LOG";
		this.PK = "user_id,post_id,log_type";
		this.siteId = siteId;
	}

	public boolean log(int userId, int postId, String type) {
		if(findCount("post_id = " + postId + " AND user_id = " + userId + " AND log_type = '" + type + "'") == 0) {
			this.item("post_id", postId);
			this.item("user_id", userId);
			this.item("site_id", this.siteId);
			this.item("log_type", type);
			this.item("reg_date", Malgn.getTimeString("yyyyMMddHHmmss"));
			return this.insert();
		}
		return false;
	}

	public boolean removeLog(int userId, int postId, String type) {
		return delete("post_id = " + postId + " AND user_id = " + userId + " AND log_type = '" + type + "'");
	}

	public boolean removeAllLog(int postId, String type) {
		return delete("post_id = " + postId + " AND log_type = '" + type + "'");
	}

}