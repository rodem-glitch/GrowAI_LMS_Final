package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class UserSiteDao extends DataObject {

	private int siteId = 0;

	public UserSiteDao() {
		this.table = "TB_USER_SITE";
		this.PK = "user_id,site_id";
	}

	public UserSiteDao(int siteId) {
		this.table = "TB_USER_SITE";
		this.PK = "user_id,site_id";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public boolean verifyUser(int userId) {
		return 0 < this.findCount("user_id = " + userId + " AND site_id = " + this.siteId);
	}

}