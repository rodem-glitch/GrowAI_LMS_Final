package dao;

import malgnsoft.db.*;

public class TutorDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.tutor.status_list.1", "0=>list.tutor.status_list.0" };

	public TutorDao() {
		this.table = "TB_TUTOR";
		this.PK = "user_id";
	}
}