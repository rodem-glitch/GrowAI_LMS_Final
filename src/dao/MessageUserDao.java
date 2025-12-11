package dao;

import malgnsoft.db.*;

public class MessageUserDao extends DataObject {

	public String[] readList = { "Y=>수신", "N=>미수신" };

	public String[] readListMsg = { "Y=>list.message_user.read_list.Y", "N=>list.message_user.read_list.N" };

	public MessageUserDao() {
		this.table = "TB_MESSAGE_USER";
		this.PK = "id";
	}
}