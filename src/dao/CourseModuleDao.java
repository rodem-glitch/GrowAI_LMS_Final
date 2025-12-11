package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseModuleDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>미사용" };

	public String[] examTypes = { "1=>정규" };
	public String[] homeworkTypes = { "1=>정규" };
	public String[] forumTypes = { "1=>정규" };
	public String[] surveyTypes = { "1=>정규" };

	public String[] evaluations = { "exam=>시험", "homework=>과제", "forum=>토론", "survey=>설문" };

	public String[] statusListMsg = { "1=>list.course_module.status_list.1", "0=>list.course_module.status_list.0" };

	public String[] examTypesMsg = { "1=>list.course_module.exam_types.1" };
	public String[] homeworkTypesMsg = { "1=>list.course_module.homework_types.1" };
	public String[] forumTypesMsg = { "1=>list.course_module.forum_types.1" };
	public String[] surveyTypesMsg = { "1=>list.course_module.survey_types.1" };

	public String[] evaluationsMsg = { "exam=>list.course_module.evaluations.exam", "homework=>list.course_module.evaluations.homework", "forum=>list.course_module.evaluations.forum", "survey=>list.course_module.evaluations.survey" };

	public CourseModuleDao() {
		this.table = "LM_COURSE_MODULE";
		this.PK = "course_id,module,module_id";
	}

	public DataSet getCourses(String module, int moduleId) throws Exception {
		return getCourses(module, moduleId, "", "");
	}

	public DataSet getCourses(String module, int moduleId, String userKind, String manageCourses) throws Exception {
		CourseDao course = new CourseDao();

		DataSet list = this.query(
			" SELECT c.* "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id " + ("C".equals(userKind) ? " AND c.id IN (" + manageCourses + ") " : "")
			+ " WHERE a.module = '" + module + "' AND a.module_id = " + moduleId + " "
			+ " AND a.status = 1 "
		);
		while(list.next()) {
			list.put("course_nm_conv", Malgn.cutString(list.s("course_nm"), 50));
			list.put("status_conv", Malgn.getItem(list.s("status"), course.statusList));
			list.put("type_conv", Malgn.getItem(list.s("course_type"), course.types));
			list.put("onoff_type_conv", Malgn.getItem(list.s("onoff_type"), course.onoffTypes));

			list.put("alltimes_block", "A".equals(list.s("course_type")));
			list.put("study_sdate_conv", Malgn.time("yyyy.MM.dd", list.s("study_sdate")));
			list.put("study_edate_conv", Malgn.time("yyyy.MM.dd", list.s("study_edate")));
			list.put("display_conv", list.b("display_yn") ? "정상" : "숨김");
		}
		list.first();
		return list;
	}

	public int getCourseCount(String module, int moduleId) {
		return getCourseCount(module, moduleId, "", "");
	}

	public int getCourseCount(String module, int moduleId, String userKind, String manageCourses) {
		return this.getOneInt(
			" SELECT COUNT(*) "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + new CourseDao().table + " c ON a.course_id = c.id " + ("C".equals(userKind) ? " AND c.id IN (" + manageCourses + ") " : "")
			+ " WHERE a.module = '" + module + "' AND a.module_id = " + moduleId + " "
			+ " AND a.status = 1 "
		);
	}
}