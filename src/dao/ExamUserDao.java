package dao;

import malgnsoft.db.*;

public class ExamUserDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.exam_user.status_list.1", "0=>list.exam_user.status_list.0" };

	public ExamUserDao() {
		this.table = "LM_EXAM_USER";
		this.PK = "exam_id,course_user_id,exam_step";
	}
}