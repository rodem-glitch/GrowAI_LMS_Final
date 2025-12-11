package dao;

import malgnsoft.db.*;

public class MessageDao extends DataObject {

	public MessageDao() {
		this.table = "TB_MESSAGE";
	}

	public int updateSendCnt(int id, int cnt) {
		return this.execute("UPDATE " + this.table + " SET send_cnt = " + cnt + " WHERE id = " + id);
	}
}