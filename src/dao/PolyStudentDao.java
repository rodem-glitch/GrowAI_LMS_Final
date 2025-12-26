package dao;

import malgnsoft.db.*;

public class PolyStudentDao extends DataObject {

	public PolyStudentDao() {
		this.table = "LM_POLY_STUDENT";
		this.PK = "course_code,open_year,open_term,bunban_code,group_code,member_key";
	}
}

