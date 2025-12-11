package dao;

import malgnsoft.db.*;

public class GroupUserDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.group_user.status_list.1", "0=>list.group_user.status_list.0" };

	public GroupUserDao() {
		this.table = "TB_GROUP_USER";
		this.PK = "group_id,user_id";
	}
}