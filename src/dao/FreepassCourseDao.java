package dao;

import malgnsoft.db.*;

public class FreepassCourseDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.freepass_course.status_list.1", "0=>list.freepass_course.status_list.0" };

	private int siteId = 0;

	public FreepassCourseDao() {
		this.table = "TB_FREEPASS_COURSE";
		this.PK = "freepass_id,course_id";
	}

	public FreepassCourseDao(int siteId) {
		this.table = "TB_FREEPASS_COURSE";
		this.PK = "freepass_id,course_id";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
	}

}