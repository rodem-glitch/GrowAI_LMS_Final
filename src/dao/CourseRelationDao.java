package dao;

import malgnsoft.db.*;

public class CourseRelationDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] statusListMsg = { "1=>list.course_relation.status_list.1", "0=>list.course_relation.status_list.0" };

	public CourseRelationDao() {
		this.table = "LM_COURSE_RELATION";
		this.PK = "course_id,module,module_id";
	}
}