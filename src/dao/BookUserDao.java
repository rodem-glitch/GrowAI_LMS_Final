package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class BookUserDao extends DataObject {

	public String[] statusList = { "1=>정상", "2=>입금대기", "3=>취소요청", "-4=>취소승인" };

	public String[] statusListMsg = { "1=>list.book_user.status_list.1", "2=>list.book_user.status_list.2", "3=>list.book_user.status_list.3", "-4=>list.book_user.status_list.-4" };

	public BookUserDao() {
		this.table = "LM_BOOK_USER";
	}

	public boolean addUser(DataSet binfo, int userId, int status) {
		return addUser(binfo, userId, status, "", "", 0);
	}

	public boolean addUser(DataSet binfo, int userId, int status, int packageId) {
		return addUser(binfo, userId, status, "", "", packageId);
	}

	public boolean addUser(DataSet binfo, int userId, int status, String startDate, String endDate) {
		return addUser(binfo, userId, status, startDate, endDate, 0);
	}

	public boolean addUser(DataSet binfo, int userId, int status, String startDate, String endDate, int packageId) {

		String permanentYn = "N";
		startDate = Malgn.time("yyyyMMdd", startDate);
		endDate = Malgn.time("yyyyMMdd", endDate);

		if("".equals(startDate) && "".equals(endDate)) {
			startDate = Malgn.time("yyyyMMdd");
			endDate = Malgn.time("yyyyMMdd", Malgn.addDate("D", binfo.i("rental_day") - 1, Malgn.time("yyyyMMdd")));
		}
		if("99991231".equals(endDate) || 0 == binfo.i("rental_day")) {
			endDate = "99991231";
			permanentYn = "Y";
		}

		item("site_id", binfo.i("site_id"));
		item("package_id", packageId);
		item("book_id", binfo.i("id"));
		item("user_id", userId);
		item("order_id", binfo.i("order_id"));
		item("order_item_id", binfo.i("order_item_id"));
		item("permanent_yn", permanentYn);
		item("start_date", startDate);
		item("end_date", endDate);
		item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		item("status", status);

		return insert();
	}

	public boolean updateRentalDate(Hashtable<String, Object> buinfo, int status) {
		DataSet bulist = new DataSet();
		bulist.addRow(buinfo);
		return updateRentalDate(bulist, status);
	}

	public boolean updateRentalDate(DataSet bulist, int status) {
		if(null == bulist) return false;

		this.item("status", status);
		this.item("start_date", Malgn.time("yyyyMMdd"));

		bulist.first();
		while(bulist.next()) {
			if(0 == bulist.i("rental_day")) {
				this.item("end_date", "99991231");
				this.item("permanent_yn", "Y");
			} else {
				this.item("end_date", Malgn.time("yyyyMMdd", Malgn.addDate("D", bulist.i("rental_day") - 1, Malgn.time("yyyyMMdd"))));
				this.item("permanent_yn", "N");
			}
	
			if(!this.update("id = " + bulist.i("book_user_id"))) return false;
		}
		return true;
	}

}