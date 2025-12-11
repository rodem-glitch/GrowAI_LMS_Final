package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseMainDao extends DataObject {

	public String[] defaultTypes = { "new=>신규", "recomm1=>추천1", "recomm2=>추천2", "recomm3=>추천3", "recomm4=>추천4", "recomm5=>추천5" };

	public CourseMainDao() {
		this.table = "LM_COURSE_MAIN";
		this.PK = "site_id,type,course_id";
	}

	public int getLastSort(int siteId, String type) {
		int max = getOneInt("SELECT count(*) FROM " + this.table + " WHERE site_id = " + siteId + " AND type = '"+ type +"'");
		return max + 1;
	}
}