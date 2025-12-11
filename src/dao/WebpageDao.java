package dao;

import java.io.File;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class WebpageDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] exceptions = { "init", "index", "page" };

	public String[] statusListMsg = { "1=>list.webpage.status_list.1", "0=>list.webpage.status_list.0" };

	public WebpageDao() {
		this.table = "TB_WEBPAGE";
	}

	public DataSet getLayouts(String path) throws Exception {
		return getLayouts(path, "layout");
	}

	public DataSet getLayouts(String path, String prefix) throws Exception {
		DataSet ds = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return ds;
		
		File[] files = dir.listFiles();
		if(files == null || 1 > files.length) return ds;
		
		for(int i = 0; i < files.length; i++) {
			String filename = files[i].getName();
			if(filename.startsWith(prefix + "_")) {
				ds.addRow();
				ds.put("id", filename.substring((prefix + "_").length(), filename.length() - 5));
				ds.put("name", filename);
			}
		}
		ds.sort("name", "asc");
		return ds;
	}
	
	public int copy(int siteId) {
		if(0 == siteId) return -1;

		DataSet list = this.find("site_id = 1 AND status = 1");
		String[] columns = list.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		int success = 0;
		while(list.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], list.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", siteId);
			this.item("status", "1");
			this.item("reg_date", now);
			if(1 > this.findCount("site_id = " + siteId + " AND code = '" + list.s("code") + "' AND status != -1") && this.insert()) success++;
		}

		return success;
	}

}