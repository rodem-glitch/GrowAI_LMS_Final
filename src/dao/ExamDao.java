package dao;

import malgnsoft.db.*;

public class ExamDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] onoffTypes = { "N=>온라인", "F=>집합" };
	
	public String[] statusListMsg = { "1=>list.exam.status_list.1", "0=>list.exam.status_list.0" };
	public String[] onoffTypesMsg = { "N=>list.exam.onoff_types.N", "F=>list.exam.onoff_types.F" };

	public ExamDao() {
		this.table = "LM_EXAM";
	}
}