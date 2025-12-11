package dao;

import malgnsoft.db.*;

public class SiteSkinDao extends DataObject {

	public String[] statusList = {"1=>사용", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.site_skin.status_list.1", "0=>list.site_skin.status_list.0" };

	public SiteSkinDao() {
		this.table = "TB_SITE_SKIN";
		this.PK = "id";
	}
}