package dao;

import malgnsoft.db.*;

public class CourseManagerDao extends DataObject {

	public CourseManagerDao() {
		this.table = "LM_COURSE_MANAGER";
		this.PK = "course_id,manager_id";
	}

	public String getManageCourses(int userId) {
		String manageCourses = "";

		DataSet list = this.find("user_id = " + userId);
		while(list.next()) {
			manageCourses += (!"".equals(manageCourses) ? "," : "") + list.i("course_id");
		}

		return manageCourses;
	}

}