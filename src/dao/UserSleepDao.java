package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class UserSleepDao extends DataObject {
	
	public String[] statusList = { "31=>휴면" };
	
	public String[] statusListMsg = { "31=>list.user_sleep.status_list.31" };

	public UserSleepDao() {
		this.table = "TB_USER_SLEEP";
		this.PK = "id";
	}

	public int awakeUser(String idx) {
		int result = 0;
		if("".equals(idx)) return -1;

		UserDao user = new UserDao();
		String now = Malgn.time("yyyyMMddHHmmss");

		DataSet slist = this.find("id IN (" + idx + ")");
		String[] columns = slist.getColumns();
		while(slist.next()) {
			//회원정보복구
			for(int i = 0; i < columns.length; i++) {
				user.item(columns[i], slist.s(columns[i]));
			}
			user.item("sleep_date", "");
			user.item("conn_date", now);
			user.item("status", "1");
			if(!user.update("id = " + slist.s("id") + " AND status = 31")) continue;
						
			//휴면정보삭제
			if(this.delete(slist.i("id"))) result++;
		}

		return result;
	}
}