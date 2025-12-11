package dao;

import malgnsoft.db.*;

public class BookRelateDao extends DataObject {

	public BookRelateDao() {
		this.table = "LM_BOOK_RELATE";
		this.PK = "book_id,relate_id";
	}
}