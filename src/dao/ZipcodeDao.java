package dao;

import malgnsoft.db.*;

public class ZipcodeDao extends DataObject {

	public ZipcodeDao() {
		this.table = "TB_ZIPCODE";
		this.PK = "seq";
	}

}