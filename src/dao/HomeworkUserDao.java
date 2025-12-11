package dao;

import malgnsoft.db.*;

public class HomeworkUserDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.homework_user.status_list.1", "0=>list.homework_user.status_list.0" };

	public HomeworkUserDao() {
		this.table = "LM_HOMEWORK_USER";
		this.PK = "homework_id,course_user_id";
	}
}