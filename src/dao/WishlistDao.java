package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class WishlistDao extends DataObject {
	
	private int siteId = 0;

	public WishlistDao() {
		this.table = "TB_WISHLIST";
		this.PK = "user_id,module,module_id";
	}

	public WishlistDao(int siteId) {
		this.table = "TB_WISHLIST";
		this.PK = "user_id,module,module_id";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public boolean isAdded(int userId, String module, int moduleId) {
		return 0 < findCount("user_id = " + userId + " AND module = '" + module + "' AND module_id = " + moduleId + " AND site_id = " + this.siteId);
	}

	public int toggle(int userId, String module, int moduleId) {
		if(findCount("user_id = " + userId + " AND module = '" + module + "' AND module_id = " + moduleId + " AND site_id = " + this.siteId) == 0) {
			this.item("user_id", userId);
			this.item("module", module);
			this.item("module_id", moduleId);
			this.item("site_id", this.siteId);
			this.item("reg_date", Malgn.getTimeString("yyyyMMddHHmmss"));
			return this.insert() ? 1 : -1;
		} else {
			return this.delete("user_id = " + userId + " AND module = '" + module + "' AND module_id = " + moduleId + " AND site_id = " + this.siteId) ? 0 : -1;
		}
	}

}