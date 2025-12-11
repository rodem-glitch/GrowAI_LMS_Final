package dao;

import malgnsoft.db.*;

public class SurveyResultDao extends DataObject {

	public SurveyResultDao() {
		this.table = "LM_SURVEY_RESULT";
		this.PK = "survey_id,survey_question_id,course_user_id";
	}
}