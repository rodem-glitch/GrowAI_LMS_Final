package dao;

import malgnsoft.db.*;

public class ForumDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] onoffTypes = { "N=>온라인", "F=>집합" };
	
	public String[] statusListMsg = { "1=>list.forum.status_list.1", "0=>list.forum.status_list.0" };
	public String[] onoffTypesMsg = { "N=>list.forum.onoff_types.N", "F=>list.forum.onoff_types.F" };

	public ForumDao() {
		this.table = "LM_FORUM";
	}
}