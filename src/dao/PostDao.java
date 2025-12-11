package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.Vector;


public class PostDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>대기" };
	public String[] procStatusList = { "1=>답변완료", "0=>답변대기" };
	public String[] displayYn = { "Y=>노출", "N=>숨김" };
	
	public String[] statusListMsg = { "1=>list.post.status_list.1", "0=>list.post.status_list.0" };
	public String[] procStatusListMsg = { "1=>list.post.proc_status_list.1", "0=>list.post.proc_status_list.0" };
	public String[] displayYnMsg = { "Y=>list.post.display_yn.Y", "N=>list.post.display_yn.N" };

	private int contentwidth = 580;
	private Vector<String> condition = new Vector<String>();

	public PostDao() {
		this.table = "TB_POST";
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
	
	public int getContentWidth() {
		return this.contentwidth;
	}

	//쓰레드
	public int getLastThread() {
		RecordSet rs = query("SELECT min(thread) AS num FROM "+ table);
		int min = -1;
		if(rs != null && rs.next()) {
			min = rs.getInt("num") - 1;
		}
		return min;
	}

	//답글갯수
	public int getReplyCount(int thread, String depth, int id) {
		return findCount("thread = " + thread + " AND depth LIKE '" + depth + "%' AND id != " + id + " AND status = 1");
	}

	//QNA답변여부
	public int getQnaReplyCount(int thread, String depth, int id) {
		return findCount("thread = " + thread + " AND depth LIKE '" + depth + "%' AND id != " + id + " AND proc_status = 1 AND status = 1");
	}

	//해당 쓰레드의 글갯수
	public int getThreadCount(int thread) {
		return findCount("thread = " + thread + " AND status = 1");
	}

	//DEPTH
	public String getThreadDepth(int thread, String depth) {
		//MS SQL
		/*		
		String sql = "SELECT depth, right(depth,1) AS foot FROM " + table + " "
						+ " WHERE thread=" + thread + " "
						+ " AND LEN(depth)=" + (depth.length() + 1) + " AND CHARINDEX('" + depth + "', depth) = 1 "
						+ " ORDER BY depth DESC";
		
		//My SQL
		String sql = "SELECT depth as head, right(depth,1) as foot FROM " + table + " "
					+ " WHERE thread = '" + thread + "' "
					+ " AND length(depth) = length('" + depth + "') + 1 AND locate('" + depth + "', depth) = 1 "
					+ " ORDER BY depth DESC";
		*/
		//Oracle
		String sql = "SELECT depth as head, substr(depth,-1) as foot FROM " + table + " "
					+ " WHERE thread = '" + thread + "' "
					+ " AND length(depth) = length('" + depth + "') + 1 AND instr(depth, '" + depth + "') = 1 "
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


	//업데이트-조회수 
	public int updateHitCount(int id) {
		return execute("UPDATE " + table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	}

	//업데이트-파일갯수
	public int updateFileCount(int id) {
		return updateFileCount(id, "post");
	}
	public int updateFileCount(int id, String module) {
		return execute("UPDATE " + table + " SET file_cnt = (SELECT COUNT(*) FROM " + new FileDao().table + " WHERE module = '" + module + "' AND module_id = '" + id + "' AND status = 1 ) WHERE id = '" + id + "'");
	}
	
	//업데이트-코멘트갯수
	public int updateCommCount(int id) {
		return updateCommCount(id, "post");
	}
	public int updateCommCount(int id, String module) {
		return execute("UPDATE " + table + " SET comm_cnt = (SELECT COUNT(*) FROM " + new CommentDao().table + " WHERE module = '" + module + "' AND module_id = '" + id + "' AND status = 1 ) WHERE id = " + id);
	}
	
	//업데이트-추천수 
	public int updateRecommCount(int id) {
		return execute("UPDATE " + table + " SET recomm_cnt = (SELECT COUNT(*) FROM " + new PostLogDao().table + " WHERE post_id = '" + id + "' AND log_type = 'recomm' ) WHERE id = " + id);
	}
	

//	//이전글 정보
//	public RecordSet getPrevPost(int bid, int thread, String depth) {
//		String cond = Malgn.join(" AND ", condition.toArray() );
//		if(!"".equals(cond)) cond = "AND " + cond;
//		return query(
//				"SELECT a.* FROM " + table + " a "
//				+ "WHERE a.board_id = " + bid + " AND a.display_yn = 'Y' AND a.status = 1 "
//				+ "AND (a.thread < " + thread + " OR (a.thread = "+ thread + " AND a.depth < '"+ depth + "')) " + cond + " "
//				+ "ORDER BY a.thread DESC, a.depth DESC "
//				, 1
//			);
//	}

//	//다음글 정보
//	public RecordSet getNextPost(int bid, int thread, String depth) {
//		String cond = Malgn.join(" AND ", condition.toArray() );
//		if(!"".equals(cond)) cond = "AND " + cond;
//		return query(
//				"SELECT a.* FROM " + table + " a "
//				+ "WHERE a.board_id = " + bid + " AND a.display_yn = 'Y' AND a.status = 1 "
//				+ "AND (a.thread > "+ thread + " OR (a.thread = "+ thread + " AND a.depth > '"+ depth +"')) " + cond + " "
//				+ "ORDER BY a.thread ASC, a.depth ASC "
//				, 1
//		);
//	}

	//이전글 정보
	public RecordSet getPrevPost(int bid, int thread, String depth) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		if(!"".equals(cond)) cond = "AND " + cond;
		return query(
				"SELECT a.*, user_nm, login_id FROM " + table + " a "
				+ "LEFT JOIN TB_USER u ON a.user_id = u.id AND u.status = 1 "
				+ "WHERE a.board_id = " + bid + " AND a.display_yn = 'Y' AND a.status = 1 "
				+ "AND (a.thread < " + thread + " OR (a.thread = "+ thread + " AND a.depth < '"+ depth + "')) " + cond + " "
				+ "ORDER BY a.thread DESC, a.depth DESC "
				, 1
		);
	}


	//다음글 정보
	public RecordSet getNextPost(int bid, int thread, String depth) {
		String cond = Malgn.join(" AND ", condition.toArray() );
		if(!"".equals(cond)) cond = "AND " + cond;
		return query(
				"SELECT a.*, user_nm, login_id FROM " + table + " a "
				+ "LEFT JOIN TB_USER u ON a.user_id = u.id AND u.status = 1 "
				+ "WHERE a.board_id = " + bid + " AND a.display_yn = 'Y' AND a.status = 1 "
				+ "AND (a.thread > "+ thread + " OR (a.thread = "+ thread + " AND a.depth > '"+ depth +"')) " + cond + " "
				+ "ORDER BY a.thread ASC, a.depth ASC "
				, 1
			);
	}

	// 게시물 이동
	public int movePost(int id, int bid) {
		return execute("UPDATE " + table + " SET board_id = " + bid + " WHERE id = " + id);
	}

}