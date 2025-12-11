package dao;

import malgnsoft.db.*;

public class HomeworkDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] onoffTypes = { "N=>온라인", "F=>집합" };
	
	public String[] statusListMsg = { "1=>list.homework.status_list.1", "0=>list.homework.status_list.0" };
	public String[] onoffTypesMsg = { "N=>list.homework.onoff_types.N", "F=>list.homework.onoff_types.F" };

	public HomeworkDao() {
		this.table = "LM_HOMEWORK";
	}
}