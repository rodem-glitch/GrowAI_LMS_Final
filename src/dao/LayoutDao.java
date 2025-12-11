/*
package dao;

import malgnsoft.db.*;
import java.io.File;

public class LayoutDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] exceptions = { "init", "index", "page" };

	public LayoutDao() {
		this.table = "TB_LAYOUT";
	}

	public DataSet getLayouts(String path) throws Exception {
		DataSet ds = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return ds;

		File[] files = dir.listFiles();
		for(int i=0; i<files.length; i++) {
			String filename = files[i].getName();
			if("layout_".equals(filename.substring(0, 7))) {
				ds.addRow();
				ds.put("id", filename.substring(7, filename.length() - 5));
				ds.put("name", filename);
			}
		}
		return ds;
	}
}
*/