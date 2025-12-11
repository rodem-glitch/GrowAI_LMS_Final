package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class GroupDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	
	public String[] statusListMsg = { "1=>list.group.status_list.1", "0=>list.group.status_list.0" };

	private int maxDiscRatio = 0;

	public GroupDao() {
		this.table = "TB_GROUP";
		this.PK = "id";
	}

	public String getUserGroup(DataSet info) {
		String groups = "";

		GroupUserDao groupUser = new GroupUserDao();
		DataSet list = query(
			"SELECT a.*"
			+ " FROM " + this.table + " a"
			+ " WHERE a.site_id = " + info.i("site_id") + " AND a.status = 1 AND ((depts LIKE '%|" + info.i("dept_id") + "|%'"
			+ " AND NOT EXISTS (SELECT 1 FROM " + groupUser.table + " WHERE add_type = 'D' AND group_id = a.id AND user_id = " + info.i("id") + ")"
			+ " ) OR ( EXISTS (SELECT 1 FROM " + groupUser.table + " WHERE add_type = 'A' AND group_id = a.id AND user_id = " + info.i("id") + ")))"
		);

		while(list.next()) {
			groups += (!"".equals(groups) ? "," : "") + list.i("id");
			if(list.i("disc_ratio") > this.maxDiscRatio) this.maxDiscRatio = list.i("disc_ratio");
		}

		return groups;
	}
	
	public Integer getMaxDiscRatio() {
		return maxDiscRatio;
	}

	public DataSet getList(int siteId) throws Exception {
		DataSet list = find("site_id = " + siteId + " AND status = 1", "*", "id ASC");
		while(list.next()) {
			list.put("name", Malgn.cutString(list.s("group_nm"), 20, ""));
		}
		list.first();
		return list;
	}
}