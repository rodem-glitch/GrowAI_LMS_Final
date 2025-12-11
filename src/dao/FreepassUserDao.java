package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class FreepassUserDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지", "2=>입금대기", "3=>취소요청", "-4=>수강취소" };
	
	public String[] statusListMsg = { "1=>list.freepass_user.status_list.1", "0=>list.freepass_user.status_list.0", "2=>list.freepass_user.status_list.2", "3=>list.freepass_user.status_list.3", "-4=>list.freepass_user.status_list.-4" };

	private int siteId = 0;

	public FreepassUserDao() {
		this.table = "TB_FREEPASS_USER";
		this.PK = "id";
	}

	public FreepassUserDao(int siteId) {
		this.table = "TB_FREEPASS_USER";
		this.PK = "id";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
	}

	public boolean addUser(DataSet finfo, int userId, int status) {
		return addUser(finfo, userId, status, "", "");
	}

	public boolean addUser(DataSet finfo, int userId, int status, String startDate, String endDate) {
		this.item("site_id", finfo.i("site_id"));
		this.item("freepass_id", finfo.i("id"));
		this.item("user_id", userId);
		this.item("order_id", finfo.i("order_id"));
		this.item("order_item_id", finfo.i("order_item_id"));

		if(!"".equals(startDate) && !"".equals(endDate)) {
			this.item("start_date", Malgn.time("yyyyMMdd", startDate));
			this.item("end_date", Malgn.time("yyyyMMdd", endDate));
		} else {
			int freepassDay = finfo.i("freepass_day");

			this.item("start_date", Malgn.time("yyyyMMdd"));
			this.item("end_date", Malgn.time("yyyyMMdd", Malgn.addDate("D", freepassDay > 0 ? freepassDay - 1 : 0, Malgn.time("yyyyMMdd"))));
		}

		this.item("limit_cnt", finfo.i("limit_cnt"));
		this.item("use_cnt", 0);
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", status);

		return this.insert();
	}

	public boolean updateDate(Hashtable<String, Object> fuinfo, int status) {
		DataSet fulist = new DataSet();
		fulist.addRow(fuinfo);
		return updateDate(fulist, status);
	}

	public boolean updateDate(DataSet fulist, int status) {
		if(null == fulist) return false;

		this.item("status", status);
		fulist.first();
		while(fulist.next()) {
			this.item("start_date", Malgn.time("yyyyMMdd"));
			this.item("end_date", Malgn.time("yyyyMMdd", Malgn.addDate("D", fulist.i("freepass_day") > 0 ? fulist.i("freepass_day") - 1 : 0, Malgn.time("yyyyMMdd"))));
			if(!this.update("id = " + fulist.i("freepass_user_id"))) return false;
		}
		return true;
	}

	public int updateCount(int freepassUserId) {
		return this.execute(
			" UPDATE " + this.table + " "
			+ " SET use_cnt = (SELECT COUNT(*) FROM " + new OrderItemDao().table + " WHERE freepass_user_id = " + freepassUserId + " AND status IN (1,2,10,20)) "
			+ " WHERE id = " + freepassUserId + ""
		);
	}

	public boolean isValid(DataSet fuinfo, DataSet oiinfo) {
		if(-1 == this.updateCount(fuinfo.i("id"))) return false;

		boolean ret = false;
		String today = Malgn.time("yyyyMMdd");
		int useCnt = this.getOneInt("SELECT use_cnt FROM " + this.table + " WHERE id = " + fuinfo.i("id"));

		if(
			fuinfo.i("user_id") == oiinfo.i("user_id") && "course".equals(oiinfo.s("product_type"))
			&& (0 == fuinfo.i("limit_cnt") || useCnt < fuinfo.i("limit_cnt"))
			&& 0 <= Malgn.diffDate("D", fuinfo.s("start_date"), today) && 0 <= Malgn.diffDate("D", today, fuinfo.s("end_date"))
		) {
			DataSet finfo = new FreepassDao().find(
				" id = " + fuinfo.i("freepass_id") + " AND site_id = " + siteId + " AND status = 1 "
				+ " AND ( "
					+ " categories LIKE '%|" + oiinfo.i("course_category_id") + "|%' "
					+ " AND NOT EXISTS (SELECT 1 FROM " + new FreepassCourseDao().table + " WHERE add_type = 'D' AND freepass_id = id AND course_id = " + oiinfo.i("course_id") + ")"
				+ " ) OR (EXISTS (SELECT 1 FROM " + new FreepassCourseDao().table + " WHERE add_type = 'A' AND freepass_id = id AND course_id = " + oiinfo.i("course_id") + "))"
			);
			ret = finfo.next();
		}
		return ret;
	}
}