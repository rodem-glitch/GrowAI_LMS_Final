package dao;

import malgnsoft.db.*;
import malgnsoft.util.Malgn;

public class CourseLessonVideoDao extends DataObject {

	public CourseLessonVideoDao() {
		this.table = "LM_COURSE_LESSON_VIDEO";
		this.PK = "course_id,lesson_id,video_id";
	}

	/**
	 * 왜 필요한가?
	 *  - 다중 영상 차시에서 서브영상 목록을 순서대로 가져오기 위해 사용합니다.
	 *  - 기존 차시/강의 구조를 건드리지 않고, “추가 테이블”로만 확장하기 위한 핵심 DAO입니다.
	 */
	public DataSet getList(int courseId, int lessonId, int siteId) {
		return this.find(
			"course_id = " + courseId + " AND lesson_id = " + lessonId + " AND site_id = " + siteId + " AND status = 1",
			"*",
			"sort ASC"
		);
	}

	public boolean deleteList(int courseId, int lessonId, int siteId) {
		return this.delete("course_id = " + courseId + " AND lesson_id = " + lessonId + " AND site_id = " + siteId);
	}

	public boolean insertItem(int courseId, int lessonId, int videoId, int sort, int siteId) {
		this.item("course_id", courseId);
		this.item("lesson_id", lessonId);
		this.item("video_id", videoId);
		this.item("sort", sort);
		this.item("site_id", siteId);
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);
		return this.insert();
	}
}

