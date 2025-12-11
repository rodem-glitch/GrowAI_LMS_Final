package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class BookMainDao extends DataObject {

	public String[] defaultTypes = { "recomm=>추천", "best=>베스트", "hot=>인기", "new=>신규", "etc1=>기타1", "etc2=>기타2", "etc3=>기타3" };
	
	public BookMainDao() {
		this.table = "LM_BOOK_MAIN";
		this.PK = "site_id,type,book_id";
	}

	public int getLastSort(int siteId, String type) {
		int max = getOneInt("SELECT count(*) FROM " + this.table + " WHERE site_id = " + siteId + " AND type = '"+ type +"'");
		return max + 1;
	}
}