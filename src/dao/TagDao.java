package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class TagDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };

	private int siteId = 0;

	public TagDao() {
		this.table = "TB_TAG";
	}

	public TagDao(int siteId) {
		this.table = "TB_TAG";
		this.siteId = siteId;
	}

	public int add(String tagNm) {

		int newId = this.getSequence();

		this.item("id", newId);
		this.item("site_id", this.siteId);
		this.item("tag_nm", tagNm);
		this.item("sort", this.getLastSort());
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);

		return this.insert() ? newId : 0;
	}

	public int getLastSort() {
		return this.getOneInt("SELECT MAX(sort) FROM " + this.table + " WHERE site_id = " + siteId + "") + 1;
	}

}
