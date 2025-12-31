package dao;

import malgnsoft.db.*;

public class PolyCourseProfDao extends DataObject {

	public PolyCourseProfDao() {
		this.table = "LM_POLY_COURSE_PROF";
		this.PK = "course_code,open_year,open_term,bunban_code,group_code,member_key";
	}
}
