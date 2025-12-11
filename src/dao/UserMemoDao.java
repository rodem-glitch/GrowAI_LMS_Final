package dao;

import malgnsoft.db.*;

public class UserMemoDao extends DataObject {

	public UserMemoDao() {
		this.table = "TB_USER_MEMO";
		this.PK = "id";
	}

}