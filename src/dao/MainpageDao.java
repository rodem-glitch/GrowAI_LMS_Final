package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class MainpageDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] displayYn = { "Y=>보임", "N=>숨김" };
	public String[] modules = { "banner1=>배너 노출", "coursemain1=>메인과정 진열", "webtvrecent1=>최근방송", "postrecent1=>최근게시물" };
	public String[] modulePrograms = { "banner1=>/main/banner_list.jsp", "coursemain1=>/inc/course_main_list.jsp", "webtvrecent1=>/main/webtv_recent_list.jsp", "postrecent1=>/main/post_list.jsp" };

	public MainpageDao() {
		this.table = "TB_MAINPAGE";
	}

	public int copy(int siteId) {
		if(0 == siteId) return -1;

		int success = 0;
		DataSet info = this.find("site_id = 1 AND status = 1", "*", "sort ASC");
		String[] columns = info.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		while(info.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], info.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", siteId);
			//this.item("sort", 1);
			//this.item("status", "1");
			this.item("reg_date", now);
			if(this.insert()) success++;
		}

		return success;
	}

}