package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class ClBoardDao extends DataObject {

	public String[] typeList = { "1=>공지사항", "2=>의견나눔", "3=>방명록", "-100=>1:1상담신청", "-200=>성적이의신청", "-300=>콘텐츠오류신고", "4=>수강후기" };
	public String[] types = { "list=>리스트", "qna=>Q&A" , "recomm=>추천"};

	public String[] baseCodes = { "notice", "qna", "review", "free" };
	public String[] baseBoardNames = { "notice=>공지사항", "qna=>Q&A", "review=>수강후기", "free=>자유게시판" };
	public String[] baseTypes = { "notice=>list", "qna=>qna", "review=>recomm", "free=>list" };
	public String[] baseWriteYns = { "notice=>N", "qna=>Y", "review=>Y", "free=>Y" };

	public String[] exceptionCodes = { "main", "curri", "exam", "homework", "forum", "survey", "pds", "epil" };

	public String[] typeListMsg = { "1=>list.cl_board.type_list.1", "2=>list.cl_board.type_list.2", "3=>list.cl_board.type_list.3", "-100=>list.cl_board.type_list.-100", "-200=>list.cl_board.type_list.-200", "-300=>list.cl_board.type_list.-300", "4=>list.cl_board.type_list.4" };
	public String[] typesMsg = { "list=>list.cl_board.types.list", "qna=>list.cl_board.types.qna" , "recomm=>list.cl_board.types.recomm"};

	public String[] baseBoardNamesMsg = { "notice=>list.cl_board.base_board_names.notice", "qna=>list.cl_board.base_board_names.qna", "review=>list.cl_board.base_board_names.review" };

	private int siteId = 0;

	public ClBoardDao() {
		this.table = "CL_BOARD";
	}

	public ClBoardDao(int siteId) {
		this.table = "CL_BOARD";
		this.siteId = siteId;
	}

	public void updateSort(int stepId, int id, int pid, int seq, int adj) {
		execute("UPDATE " + table + " SET sort = sort * 10 WHERE step_id = " + stepId + " AND parent_id = " + pid);
		execute("UPDATE " + table + " SET sort = " + (seq * 10 + adj) + " WHERE step_id = " + stepId + " AND id = " + id);

		updateGroupSort(stepId, pid);
	}

	public void updateGroupSort(int stepId, int pid) {
		DataSet list = query("SELECT id, sort FROM " + table + " WHERE step_id = " + stepId + " AND parent_id = " + pid + " ORDER BY status DESC, sort ASC");
		int i = 0;
		while(list.next()) {
			i++;
			execute("UPDATE " + table + " SET sort = " + i + " WHERE step_id = " + stepId + " AND id = " + list.getInt("id"));
		}
	}

	public String getConcat(String[] arr) {
		String dbType = getDBType();
		String str = "";
		if("mssql".equals(dbType)) {
			str = Malgn.join(" + ", arr);
		} else if("oracle".equals(dbType)) {
			str = Malgn.join(" || ", arr);
		} else {
			str = "CONCAT(" + Malgn.join(", ", arr) + ")";
		}
		return str;
	}

	public int autoSort(String courseId) {
		DataSet list = this.find("course_id = " + courseId + "", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE id = " + list.i("id") + "");
			sort++;
		}
		return 1;
	}

	public boolean insertBoard(int courseId) {
		DataSet codes = Malgn.arr2loop(this.baseCodes);

		while(codes.next()) {
			String code = codes.s("id");
			this.item("site_id", this.siteId);
			this.item("course_id", courseId);
			this.item("code", code);
			this.item("board_nm", Malgn.getItem(code, this.baseBoardNames));
			this.item("base_yn", "Y");
			this.item("board_type", Malgn.getItem(code, this.baseTypes));
			this.item("content", "");
			this.item("sort", codes.i("__idx"));
			this.item("write_yn", Malgn.getItem(code, this.baseWriteYns));
			this.item("link", "");
			this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
			this.item("status", 1);
			if(!this.insert()) return false;
		}

		return true;
	}
}
