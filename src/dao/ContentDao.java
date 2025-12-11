package dao;

import malgnsoft.db.*;

public class ContentDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };

	public ContentDao() {
		this.table = "LM_CONTENT";
	}
}