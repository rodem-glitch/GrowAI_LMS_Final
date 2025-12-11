package dao;

import malgnsoft.db.*;

public class LibraryDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.library.status_list.1", "0=>list.library.status_list.0" };

	public LibraryDao() {
		this.table = "LM_LIBRARY";
	}

	public int updateDownloadCount(int id) {
		return execute("UPDATE " + table + " SET download_cnt = download_cnt + 1 WHERE id = " + id + "");
	}
}