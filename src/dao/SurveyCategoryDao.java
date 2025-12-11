package dao;

import malgnsoft.db.*;

public class SurveyCategoryDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.survey_category.status_list.1", "0=>list.survey_category.status_list.0" };

	public SurveyCategoryDao() {
		this.table = "LM_SURVEY_CATEGORY";
		this.PK = "id";
	}

	public DataSet getCategories(int siteId) {
		return find("site_id = " + siteId + " AND status = 1", "id, category_nm", "category_nm ASC");
	}

	public int updateItemCnt(int id) {
		return execute(
			"UPDATE " + this.table + " "
			+ " SET item_cnt = ( "
				+ " SELECT COUNT(*) FROM " + new SurveyQuestionDao().table + " "
				+ " WHERE status = 1 AND category_id = " + id + " "
			+ " ) WHERE id = " + id + ""
		);
	}
}