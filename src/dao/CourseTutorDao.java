package dao;

import malgnsoft.db.*;

public class CourseTutorDao extends DataObject {
	
	public String[] types = { "major=>주강사", "minor=>보조강사" };
	public String[] typesMsg = { "major=>list.course_tutor.types.major", "minor=>list.course_tutor.types.minor" };

	public CourseTutorDao() {
		this.table = "LM_COURSE_TUTOR";
		this.PK = "course_id,user_id,type";
	}

	public String getTutorName(int courseId) {
		DataSet rs = this.query(
			"SELECT b.tutor_nm"
			+ " FROM " + this.table + " a"
			+ " JOIN " + new TutorDao().table + " b ON b.user_id = a.user_id"
			+ " WHERE a.course_id = " + courseId
			+ " ORDER BY b.sort ASC, b.tutor_nm ASC "
		);
		String name = "";
		while(rs.next()) {
			if("".equals(name)) name += rs.s("tutor_nm");
			else name += ", " + rs.s("tutor_nm");
		}
		return name;
	}

	public String getTutorSummary(int courseId) {
		DataSet rs = this.query(
			"SELECT b.tutor_nm"
			+ " FROM " + this.table + " a"
			+ " JOIN " + new TutorDao().table + " b ON b.user_id = a.user_id"
			+ " WHERE a.course_id = " + courseId
			+ " ORDER BY b.sort ASC, b.tutor_nm ASC "
		);
		rs.next();
		if(1 < rs.size()) {
			return rs.s("tutor_nm") + " 외 " + (rs.size() - 1) + "명";
		} else {
			return rs.s("tutor_nm");
		}
	}
}