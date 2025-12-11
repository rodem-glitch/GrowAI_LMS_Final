package dao;

import malgnsoft.db.*;

public class CourseTargetDao extends DataObject {

	public CourseTargetDao() {
		this.table = "LM_COURSE_TARGET";
		this.PK = "group_id,course_id";
	}
}