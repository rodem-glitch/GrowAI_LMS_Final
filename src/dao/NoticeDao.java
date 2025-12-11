package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.Vector;


public class NoticeDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>대기" };
	public String[] categories = { "1=>공지", "2=>기능개선", "3=>가이드", "4=>자료" };
	
	public String[] statusListMsg = { "1=>list.notice.status_list.1", "0=>list.notice.status_list.0" };
	public String[] categoriesMsg = { "1=>list.notice.categories.1", "2=>list.notice.categories.2", "3=>list.notice.categories.3", "4=>list.notice.categories.4" };

	private Vector<String> condition = new Vector<String>();

	public NoticeDao() {
		this.table = "TB_NOTICE";
		this.PK = "id";
	}

	//조건-이전/다음글
	public void appendSearch(String field, String keyword) {
		appendSearch(field, keyword, "=", 1);
	}
	
	public void appendSearch(String field, String keyword, String oper) {
		int type = 1;
		if("LIKE".equals(oper.toUpperCase())) type = 2;
		appendSearch(field, keyword, oper, type);
	}
	
	public void appendSearch(String field, String keyword, String oper, int type) {
		if(keyword != null && !"".equals(keyword)) {
			if(type == 1) keyword = "'" + keyword + "'";
			else if(type == 2) keyword = "'%" + keyword + "%'";
			condition.add(field + " " + oper + " " + keyword);
		}
	}
	public void appendWhere(String cond) {
		condition.add(cond);
	}
	
	//업데이트-조회수 
	public int updateHitCount(int id) {
		return execute("UPDATE " + table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	}

	//이전글 정보
	public RecordSet getPrevPost(int id) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		if(!"".equals(cond)) cond = "AND " + cond;
		return query(
				"SELECT a.* FROM " + table + " a "
				+ "WHERE a.id < " + id + " " + cond + " "
				+ "ORDER BY a.id DESC "
				, 1
			);
	}

	//다음글 정보
	public RecordSet getNextPost(int id) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		if(!"".equals(cond)) cond = "AND " + cond;
		return query(
				"SELECT a.* FROM " + table + " a "
				+ "WHERE a.id > " + id + " " + cond + " "
				+ "ORDER BY a.id ASC "
				, 1
			);
	}

}