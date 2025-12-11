package dao;

import malgnsoft.db.*;

public class LmCategoryTargetDao extends DataObject {

	public LmCategoryTargetDao() {
		this.table = "LM_CATEGORY_TARGET";
		this.PK = "category_id,group_id";
	}
}