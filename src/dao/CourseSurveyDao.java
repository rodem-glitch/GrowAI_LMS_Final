package dao;

import malgnsoft.db.*;

public class CourseSurveyDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	public String[] statusListMsg = { "1=>list.course_survey.status_list.1", "0=>list.course_survey.status_list.0" };

	public CourseSurveyDao() {
		this.table = "LM_COURSE_SURVEY";
		this.PK = "id";
	}
}