package dao;

import malgnsoft.db.*;

public class SurveyItemDao extends DataObject {

	public SurveyItemDao() {
		this.table = "LM_SURVEY_ITEM";
		this.PK = "survey_id,question_id";
	}

	public int autoSort(int siteId, int surveyId) {
		DataSet list = this.find("site_id = " + siteId + " AND survey_id = " + surveyId + " AND status = 1", "survey_id, question_id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE survey_id = " + list.i("survey_id") + " AND question_id = " + list.i("question_id") + " AND site_id = " + siteId + " AND status = 1");
			sort++;
		}
		return 1;
	}
}