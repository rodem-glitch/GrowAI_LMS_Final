package dao;

import malgnsoft.db.*;

public class KtalkUserDao extends DataObject {

	public KtalkUserDao() {
		this.table = "TB_KTALK_USER";
		this.PK = "id";
	}

}