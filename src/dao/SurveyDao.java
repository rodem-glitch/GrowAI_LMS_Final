package dao;

import malgnsoft.db.*;

public class SurveyDao extends DataObject {

	public String[] statusList = {"1=>사용", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.survey.status_list.1", "0=>list.survey.status_list.0" };

	public SurveyDao() {
		this.table = "LM_SURVEY";
		this.PK = "id";
	}

	public int updateItemCount(int id) {
		return execute(
			"UPDATE " + this.table + " SET "
			+ " item_cnt = (SELECT COUNT(*) FROM " + new SurveyItemDao().table + " WHERE survey_id = " + id + " AND status = 1) "
			+ " WHERE id = " + id + ""
		);
	}
}