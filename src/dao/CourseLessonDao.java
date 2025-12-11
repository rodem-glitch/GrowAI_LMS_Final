package dao;

import malgnsoft.db.*;
import malgnsoft.util.Malgn;

public class CourseLessonDao extends DataObject {

	public CourseLessonDao() {
		this.table = "LM_COURSE_LESSON";
		this.PK = "course_id,lesson_id,chapter";
	}

	public void autoSort(int courseId) {
		DataSet list = this.query(
			" SELECT a.lesson_id, a.chapter, cs.id section_id "
			+ " FROM " + this.table + " a "
			+ " LEFT JOIN " + new CourseSectionDao().table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1"
			+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
			+ " ORDER BY a.chapter ASC "
		);
		int chapter = 1;
		int sectionId = 0;
		while(list.next()) {
			if(sectionId != list.i("section_id") && 0 < list.i("section_id")) sectionId = list.i("section_id");

			this.execute("UPDATE " + this.table + " SET section_id = " + sectionId + ", chapter = " + chapter + " WHERE course_id = " + courseId + " AND chapter = " + list.i("chapter") + " AND lesson_id = " + list.i("lesson_id") + " ");
			chapter++;
		}
	}
}