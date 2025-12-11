package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class SubjectDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.subject.status_list.1", "0=>list.subject.status_list.0" };

	public SubjectDao() {
		this.table = "LM_SUBJECT";
		this.PK = "id";
	}

	public DataSet getList(int siteId) {
		return find("status = 1 AND site_id = " + siteId + "", "*", "course_nm ASC");
	}
}