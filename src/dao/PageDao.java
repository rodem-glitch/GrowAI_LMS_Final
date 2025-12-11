package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.io.File;

public class PageDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.page.status_list.1", "0=>list.page.status_list.0" };

	public PageDao() {
		this.table = "TB_PAGE";
	}

	public DataSet getLayouts(String path) throws Exception {
		DataSet ds = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return ds;
		try {
			File[] files = dir.listFiles();
			if(null == files) throw new NullPointerException();
			for (int i = 0; i < files.length; i++) {
				if(null == files[i]) throw new NullPointerException();
				String filename = files[i].getName();
				if (filename.startsWith("layout_")) {
					ds.addRow();
					ds.put("id", filename.substring(7, filename.length() - 5));
					ds.put("name", filename);
				}
			}
			return ds;
		} catch (NullPointerException npe) {
			Malgn.errorLog("NullPointerException : PageDao.getLayouts() : " + npe.getMessage(), npe);
			return new DataSet();
		}

	}
}
