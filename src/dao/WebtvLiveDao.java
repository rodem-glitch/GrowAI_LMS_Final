package dao;

import malgnsoft.db.*;

public class WebtvLiveDao extends DataObject {

	public String[] statusList = new String[] { "1=>정상", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.webtv_live.status_list.1", "0=>list.webtv_live.status_list.0" };

	public WebtvLiveDao() {
		this.table = "LM_WEBTV_LIVE";
		this.PK = "id";
	}
}