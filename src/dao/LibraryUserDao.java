package dao;

import malgnsoft.db.*;

public class LibraryUserDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.library_user.status_list.1", "0=>list.library_user.status_list.0" };

	public LibraryUserDao() {
		this.table = "LM_LIBRARY_USER";
	}
}