package dao;

import malgnsoft.db.*;

public class WebtvDao extends DataObject {

	public String[] commentList = { "Y=>사용", "N=>중지" };
	public String[] displayList = { "Y=>노출", "N=>중지" };
	public String[] statusList = { "1=>정상", "0=>중지" };

	public String[] grades = { "H1=>고1", "H2=>고2", "H3=>고3", "M1=>중1", "M2=>중2", "M3=>중3" };
	public String[] terms = { "1=>1학기", "S=>여름학기", "2=>2학기", "W=>겨울학기" };
	public String[] subjects = { "K=>국어", "E=>영어", "M=>수학", "SO=>사회", "SC=>과학" };
	
	public String[] commentListMsg = { "Y=>list.webtv.comment_list.Y", "N=>list.webtv.comment_list.N" };
	public String[] displayListMsg = { "Y=>list.webtv.display_list.Y", "N=>list.webtv.display_list.N" };
	public String[] statusListMsg = { "1=>list.webtv.status_list.1", "0=>list.webtv.status_list.0" };

	private int contentwidth = 580;

	public WebtvDao() {
		this.table = "LM_WEBTV";
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
		return updateCommCount(id, "webtv");
	}
	public int updateCommCount(int id, String module) {
		return execute("UPDATE " + table + " SET comm_cnt = (SELECT COUNT(*) FROM " + new CommentDao().table + " WHERE module = '" + module + "' AND module_id = '" + id + "' AND status = 1 ) WHERE id = " + id);
	}
	
	//업데이트-추천수 
	public int updateRecommCount(int id) {
		return execute("UPDATE " + table + " SET recomm_cnt = (SELECT COUNT(*) FROM " + new WebtvRecommDao().table + " WHERE webtv_id = '" + id + "' ) WHERE id = " + id);
	}
	
	public int getContentWidth() {
		return this.contentwidth;
	}

}