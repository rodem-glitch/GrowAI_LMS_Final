package dao;

import malgnsoft.db.*;

public class PolyCourseDao extends DataObject {

	public PolyCourseDao() {
		this.table = "LM_POLY_COURSE";
		this.PK = "course_code,open_year,open_term,bunban_code,group_code";
	}
}

