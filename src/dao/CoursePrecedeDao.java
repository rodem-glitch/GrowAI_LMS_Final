package dao;

import malgnsoft.db.*;

public class CoursePrecedeDao extends DataObject {

	public CoursePrecedeDao() {
		this.table = "LM_COURSE_PRECEDE";
		this.PK = "course_id,precede_id";
	}
}