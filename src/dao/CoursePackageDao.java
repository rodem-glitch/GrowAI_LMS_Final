package dao;

import malgnsoft.db.*;

public class CoursePackageDao extends DataObject {

	public CoursePackageDao() {
		this.table = "LM_COURSE_PACKAGE";
		this.PK = "package_id,course_id";
	}

	public void autoSort(int packageId) {
		this.execute("UPDATE " + this.table + " SET sort = sort * 1000 WHERE package_id = " + packageId + " ");
		DataSet list = this.find("package_id = " + packageId + " ", "course_id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + this.table + " SET sort = " + sort + " WHERE sort = " + list.i("sort") + " AND course_id = " + list.i("course_id") + " AND package_id = " + packageId);
			sort++;
		}
	}

	public int getLastSort(int packageId) {
		int max = getOneInt("SELECT MAX(sort) FROM " + this.table + " WHERE package_id = " + packageId);
		return max + 1;
	}

	public DataSet getCourses(int packageId) {
		return this.query(
			" SELECT a.*, c.* "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + new CourseDao().table + " c ON a.course_id = c.id AND c.onoff_type != 'P' AND c.status = 1 "
			+ " WHERE a.package_id = " + packageId
			+ " ORDER BY a.sort ASC "
		);
	}
}