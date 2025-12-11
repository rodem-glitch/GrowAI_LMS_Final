package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class PostTemplateDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.post_template.status_list.1", "0=>list.post_template.status_list.0" };
	private int siteId = 0;

	public PostTemplateDao() {
		this.table = "TB_POST_TEMPLATE";
	}

	public PostTemplateDao(int siteId) {
		this.table = "TB_POST_TEMPLATE";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public DataSet getTemplateList(int boardId) {
		if(0 == siteId || 0 == boardId) return new DataSet();
		return this.find("site_id = " + siteId + " AND board_id = " + boardId + " AND status = 1", "id, template_nm", "template_nm ASC");
	}

	public String getTemplate(int templateId) {
		return this.getOne("SELECT content FROM " + this.table + " WHERE id = ? AND site_id = " + siteId + " AND status = 1", new Integer[] {templateId});
	}
}