package dao;

import malgnsoft.db.*;

public class SmsUserDao extends DataObject {

	public SmsUserDao() {
		this.table = "TB_SMS_USER";
		this.PK = "id";
	}
}