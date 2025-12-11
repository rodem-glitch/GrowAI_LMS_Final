package dao;

import malgnsoft.db.*;

public class BookTargetDao extends DataObject {

	public BookTargetDao() {
		this.table = "LM_BOOK_TARGET";
		this.PK = "book_id,group_id";
	}
}