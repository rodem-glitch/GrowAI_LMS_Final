package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import java.util.*;

public class CategoryDao extends DataObject {

	public String[] modules = {"faq=>faq", "qna=>qna", "out=>out"};

	public CategoryDao() {
		this.table = "TB_CATEGORY";
		this.PK = "id";
	}

	public RecordSet getList(String module, int mid, int sid) {
		return this.find("site_id = " + sid + " AND status = 1 AND module = '" + module + "' AND module_id = " + mid + "", "*", "sort ASC");
	}

	public RecordSet getList(String module, int sid) {
		return this.find("site_id = " + sid + " AND status = 1 AND module = '" + module + "'", "*", "sort ASC");
	}

	public String getName(DataSet categories, String id) {
		categories.first();
		while(categories.next()) {
			if(id.equals(categories.s("id"))) return categories.s("category_nm");
		}
		return "";
	}

	public int sort(int id, int num, int pnum) {
		if(id == 0 || num == 0 || pnum == 0) return -1;
		DataSet info = this.find("id = " + id);
		if(!info.next()) return -1;
		this.execute("UPDATE " + this.table +  " SET sort = sort * 1000 WHERE site_id = " + info.i("site_id") + " AND status = 1 AND module = '" + info.s("module") + "' AND module_id = " + info.i("module_id"));
		this.execute("UPDATE " + this.table +  " SET sort = " + num + " * 1000" + (pnum <= num ? "+1" : "-1") + " WHERE id = " + id + "");
		return autoSort(info.s("module"), info.i("module_id"), info.i("site_id"));
	}

	public int autoSort(String module, int module_id, int sid) {
		DataSet list = this.find("site_id = " + sid + " AND status = 1 AND module = '" + module + "' AND module_id = " + module_id + "", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + this.table +  " SET sort = " + sort + " WHERE id = " + list.s("id") + "");
			sort++;
		}
		return 1;
	}
}