package dao;

import malgnsoft.db.*;

public class ExamResultDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.exam_result.status_list.1", "0=>list.exam_result.status_list.0" };

	public ExamResultDao() {
		this.table = "LM_EXAM_RESULT";
		this.PK = "exam_id,exam_step,question_id,course_user_id";
	}
}