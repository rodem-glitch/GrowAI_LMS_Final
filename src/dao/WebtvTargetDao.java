package dao;

import malgnsoft.db.*;

public class WebtvTargetDao extends DataObject {

	public WebtvTargetDao() {
		this.table = "LM_WEBTV_TARGET";
		this.PK = "webtv_id,group_id";
	}
}