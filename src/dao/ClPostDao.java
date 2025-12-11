package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class ClPostDao extends DataObject {

	public String[] statusList = {"1=>Y", "0=>N" };
	public String[] procStatusList = { "1=>답변완료", "0=>답변대기" };
	public String[] displayYn = { "Y=>노출", "N=>숨김" };

	public String[] procStatusListMsg = { "1=>list.cl_post.proc_status_list.1", "0=>list.cl_post.proc_status_list.0" };
	public String[] displayYnMsg = { "Y=>list.cl_post.display_yn.Y", "N=>list.cl_post.display_yn.N" };

	private Vector<String> condition = new Vector<String>();

	public ClPostDao() {
		this.table = "CL_POST";
		this.PK = "id";
	}

	public void updateHitCount(int id) {
		execute("UPDATE " + this.table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
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

	public void addSearch(String field, String keyword) {
		addSearch(field, keyword, "=", 1);
	}

	public void addSearch(String field, String keyword, String oper) {
		int type = 1;
		if("LIKE".equals(oper.toUpperCase())) type = 2;
		addSearch(field, keyword, oper, type);
	}

	public void addSearch(String field, String keyword, String oper, int type) {
		if(keyword != null && !"".equals(keyword)) {
			if(type == 1) keyword = "'" + keyword + "'";
			else if(type == 2) keyword = "'%" + keyword + "%'";
			condition.add(field + " " + oper + " " + keyword);
		}
	}
	public void addWhere(String cond) {
		condition.add(cond);
	}


	public int getLastThread() {
		RecordSet rs = query("SELECT min(thread) AS num FROM "+ table);
		int min = -1;
		if(rs != null && rs.next()) {
			min = rs.getInt("num") - 1;
		}
		return min;
	}

	public String getThreadDepth(int thread, String depth) {
		String sql = "SELECT depth as head, right(depth,1) as foot FROM " + table + " "
					+ " WHERE thread = '" + thread + "' "
					+ " AND length(depth) = length('" + depth + "') + 1 AND locate('" + depth + "', depth) = 1 "
					+ " ORDER BY depth DESC";

		RecordSet rs = selectLimit(sql, 1);

		String nDepth = depth + "A";
		if(rs != null && rs.next()) {
			String ord_head = rs.getString("head").length() > 1 ? rs.getString("head").substring(0, rs.getString("head").length() - 1) : "";
			String ord_foot = "" + (char)(rs.getString("foot").hashCode() + 1);
			nDepth = ord_head + ord_foot;
		}
		return nDepth;
	}

	public RecordSet getPrevPost(int boardId, int thread, String depth) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		return selectLimit(
			"SELECT a.*, b.board_nm, u.login_id "
			+ " FROM " + table + " a "
			+ " INNER JOIN " + new ClBoardDao().table + " b ON a.board_id = b.id "
			+ " LEFT JOIN " + new UserDao().table + " u ON a.user_id = u.id "
			+ " WHERE a.board_id = " + boardId + " AND a.display_yn = 'Y' AND a.status = 1 AND (a.thread < " + thread + " OR (a.thread = " + thread + " AND a.depth < '"+ depth + "'))"
			+ (!"".equals(cond) ? " AND " + cond : "")
			+ " ORDER BY a.board_id, a.thread desc, a.depth desc"
			, 1
		);
	}


	public RecordSet getNextPost(int boardId, int thread, String depth) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		return selectLimit(
			"SELECT a.*, b.board_nm, u.login_id "
			+ " FROM " + table + " a "
			+ " INNER JOIN " + new ClBoardDao().table + " b ON a.board_id = b.id "
			+ " LEFT JOIN " + new UserDao().table + " u ON a.user_id = u.id "
			+ " WHERE a.board_id = " + boardId + " AND a.display_yn = 'Y' AND a.status = 1 AND (a.thread > " + thread + " OR (a.thread = " + thread + " AND a.depth > '"+ depth +"'))"
			+ (!"".equals(cond) ? " AND " + cond : "")
			+ " ORDER BY a.board_id, a.thread, a.depth"
			, 1
		);
	}

	public String getFtypeIcon(String types) {
		String str = "";
		if(!"".equals(types)) {
			String[] arr = types.split("\\,");
			for(int i=0; i<arr.length; i++) {
				str += " <img src=\"../html/images/classroom/ico_" + arr[i] + ".gif\" width=\"10\" height=\"11\" align=\"absmiddle\">";
			}
		}
		return str;
	}

	//업데이트-파일갯수
	public int updateFileCount(int id) {
		return updateFileCount(id, "post");
	}
	public int updateFileCount(int id, String module) {
		return execute(
			"UPDATE " + table + " SET file_cnt = ( "
				+ " SELECT COUNT(*) FROM " + new ClFileDao().table + " "
				+ " WHERE module = '" + module + "' AND module_id = '" + id + "' AND status = 1 "
			+ " ) WHERE id = '" + id + "'"
		);
	}
	
	//업데이트-코멘트갯수
	public int updateCommCount(int id) {
		return updateCommCount(id, "post");
	}
	public int updateCommCount(int id, String module) {
		return execute("UPDATE " + table + " SET comm_cnt = (SELECT COUNT(*) FROM " + new ClCommentDao().table + " WHERE module = '" + module + "' AND module_id = '" + id + "' AND status = 1 ) WHERE id = " + id);
	}
}