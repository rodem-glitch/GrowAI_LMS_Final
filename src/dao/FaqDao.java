package dao;

import malgnsoft.db.*;

public class FaqDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.faq.status_list.1", "0=>list.faq.status_list.0" };

	public FaqDao() {
		this.table = "TB_FAQ";
	}

	//업데이트-조회수 
	public int updateHitCount(int id) {
		return execute("UPDATE " + table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	}

}