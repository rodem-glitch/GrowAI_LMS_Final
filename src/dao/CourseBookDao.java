package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseBookDao extends DataObject {
	
	public CourseBookDao() {
		this.table = "LM_COURSE_BOOK";
		this.PK = "course_id,book_id";
	}

	public DataSet getCourses(int id) throws Exception {
		CourseDao course = new CourseDao();
		CourseTutorDao courseTutor = new CourseTutorDao();
		LmCategoryDao category = new LmCategoryDao("course");

		DataSet list = this.query(
			"SELECT c.*, cg.category_nm "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status = 1 AND c.display_yn = 'Y' "
			+ " LEFT JOIN " + category.table + " cg ON c.category_id = cg.id AND cg.module = 'course' AND cg.status = 1 "
			+ " WHERE a.book_id = " + id + " "
		);
		while(list.next()) {
			list.put("course_nm_conv", Malgn.cutString(list.s("course_nm"), 50));
			list.put("status_conv", Malgn.getItem(list.s("status"), course.statusList));
			list.put("type_conv", Malgn.getItem(list.s("course_type"), course.types));

			list.put("alltimes_block", "A".equals(list.s("course_type")));
			list.put("study_sdate_conv", Malgn.time("yyyy.MM.dd", list.s("study_sdate")));
			list.put("study_edate_conv", Malgn.time("yyyy.MM.dd", list.s("study_edate")));

			list.put("tutor_nm", courseTutor.getTutorSummary(list.i("id")));
		}
		list.first();
		return list;
	}

	public int getCourseCount(int id) {
		return this.findCount("book_id = " + id + "");
	}
}