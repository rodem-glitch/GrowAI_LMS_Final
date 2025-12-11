package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class WebtvPlaylistDao extends DataObject {
	
	private int siteId = 0;

	public WebtvPlaylistDao() {
		this.table = "LM_WEBTV_PLAYLIST";
		this.PK = "site_id,category_id,webtv_id";
	}

	public WebtvPlaylistDao(int siteId) {
		this.table = "LM_WEBTV_PLAYLIST";
		this.PK = "site_id,category_id,webtv_id";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public int getLastSort(int categoryId) {
		int max = getOneInt("SELECT count(*) FROM " + this.table + " WHERE site_id = " + this.siteId + " AND category_id = '" + categoryId + "'");
		return max + 1;
	}
}