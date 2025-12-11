package dao;

import malgnsoft.db.*;

public class SurveyQuestionDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] types = { "1=>단일선택", "M=>다중선택", "2=>단답형", "3=>서술형" };

	public String[] statusListMsg = { "1=>list.survey_question.status_list.1", "0=>list.survey_question.status_list.0" };
	public String[] typesMsg = { "1=>list.survey_question.types.1", "2=>list.survey_question.types.2", "3=>list.survey_question.types.3" };
	
	public SurveyQuestionDao() {
		this.table = "LM_SURVEY_QUESTION";
		this.PK = "id";
	}
}