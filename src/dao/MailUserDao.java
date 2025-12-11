package dao;

import malgnsoft.db.*;

public class MailUserDao extends DataObject {

	public MailUserDao() {
		this.table = "TB_MAIL_USER";
		this.PK = "id";
	}
}