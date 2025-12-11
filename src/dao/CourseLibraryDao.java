package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseLibraryDao extends DataObject {
	
	public CourseLibraryDao() {
		this.table = "LM_COURSE_LIBRARY";
		this.PK = "course_id,library_id";
	}

	public DataSet getCourses(int id) throws Exception {
		CourseDao course = new CourseDao();

		DataSet list = this.query(
			"SELECT c.* "
			+ " FROM " + this.table + " a "
			+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id "
			+ " WHERE a.book_id = " + id + " "
		);
		while(list.next()) {
			list.put("course_nm_conv", Malgn.cutString(list.s("course_nm"), 50));
			list.put("status_conv", Malgn.getItem(list.s("status"), course.statusList));
			list.put("type_conv", Malgn.getItem(list.s("course_type"), course.types));

			list.put("alltimes_block", "A".equals(list.s("course_type")));
			list.put("study_sdate_conv", Malgn.time("yyyy.MM.dd", list.s("study_sdate")));
			list.put("study_edate_conv", Malgn.time("yyyy.MM.dd", list.s("study_edate")));
		}
		list.first();
		return list;
	}

	public int getCourseCount(int id) {
		return this.findCount("library_id = " + id + "");
	}
}