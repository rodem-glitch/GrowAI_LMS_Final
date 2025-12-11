package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseAutoDao extends DataObject {
	
	public int siteId = 0;

	public CourseAutoDao() {
		this.table = "LM_COURSE_AUTO";
		this.PK = "course_id,auto_id,site_id";
	}

	public CourseAutoDao(int siteId) {
		this.table = "LM_COURSE_AUTO";
		this.PK = "course_id,auto_id,site_id";
		this.siteId = siteId;
	}
	
	public boolean add(int autoId, int courseId) {
		this.item("site_id", this.siteId);
		this.item("auto_id", autoId);
		this.item("course_id", courseId);
		return this.insert();
	}

	public boolean del(int autoId, int courseId) {
		return -1 < this.execute("DELETE FROM " + this.table + " WHERE site_id = " + this.siteId + " AND auto_id = " + autoId + " AND course_id = " + courseId + "");
	}
}