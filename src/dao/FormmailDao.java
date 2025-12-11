package dao;

import malgnsoft.db.*;

public class FormmailDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.formmail.status_list.1", "0=>list.formmail.status_list.0" };

	public FormmailDao() {
		this.table = "TB_FORMMAIL";
		this.PK = "id";
	}

}