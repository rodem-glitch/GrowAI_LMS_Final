package dao;

import malgnsoft.db.*;

public class SurveyUserDao extends DataObject {

	public SurveyUserDao() {
		this.table = "LM_SURVEY_USER";
		this.PK = "survey_id,course_user_id";
	}
}