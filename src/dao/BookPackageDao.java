package dao;

import malgnsoft.db.*;

public class BookPackageDao extends DataObject {

	public BookPackageDao() {
		this.table = "LM_BOOK_PACKAGE";
		this.PK = "package_id,book_id";
	}

	public void autoSort(int packageId) {
		this.execute("UPDATE " + this.table + " SET sort = sort * 1000 WHERE package_id = " + packageId + " ");
		DataSet list = this.find("package_id = " + packageId + " ", "book_id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + this.table + " SET sort = " + sort + " WHERE sort = " + list.i("sort") + " AND book_id = " + list.i("book_id") + " AND package_id = " + packageId);
			sort++;
		}
	}

	public int getLastSort(int packageId) {
		int max = getOneInt("SELECT MAX(sort) FROM " + this.table + " WHERE package_id = " + packageId);
		return max + 1;
	}
	
	public DataSet getBooks(int packageId) {
		return this.query(
			" SELECT a.*, b.* "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + new BookDao().table + " b ON a.book_id = b.id AND b.book_type != 'P' AND b.status = 1 "
			+ " WHERE a.package_id = " + packageId
			+ " ORDER BY a.sort ASC "
		);
	}
}