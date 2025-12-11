package dao;

import malgnsoft.db.*;

public class BookDao extends DataObject {

	public String[] types = {"R=>실물책", "E=>전자책"};
	public String[] packageTypes = {"R=>실물책", "E=>전자책", "P=>패키지"};
	public String[] statusList = {"1=>사용", "0=>중지"};
	public String[] taxfreeYn = {"Y=>면세", "N=>과세"};
	public String[] displayYn = {"Y=>정상", "N=>숨김"};
	public String[] deliveryTypes = {"A=>착불", "B=>선불"};
	public String[] ordList = {
								"id asc=>a.id asc", "id desc=>a.id desc", "pd asc=>a.pub_date asc", "pd desc=>a.pub_date desc"
								, "st asc=>a.sort asc", "st desc=>a.sort desc", "as asc=>a.allsort asc", "as desc=>a.allsort desc"
								, "ry asc=>a.recomm_yn asc", "ry desc=>a.recomm_yn desc"
							};

	public String[] typesMsg = {"R=>list.book.types.R", "E=>list.book.types.E"};
	public String[] packageTypesMsg = {"R=>list.book.package_types.R", "E=>list.book.package_types.E", "P=>list.book.package_types.P"};
	public String[] statusListMsg = {"1=>list.book.status_list.1", "0=>list.book.status_list.0"};
	public String[] taxfreeYnMsg = {"Y=>list.book.taxfree_yn.Y", "N=>list.book.taxfree_yn.N"};
	public String[] displayYnMsg = {"Y=>list.book.display_yn.Y", "N=>list.book.display_yn.N"};
	public String[] deliveryTypesMsg = {"A=>list.book.delivery_types.A", "B=>list.book.delivery_types.B"};

	public BookDao() {
		this.table = "LM_BOOK";
		this.PK = "id";
	}

	public DataSet getBookList(int siteId) {
		return this.find("status = 1 AND site_id = " + siteId + "", "*", "book_nm ASC, reg_date DESC");
	}

}