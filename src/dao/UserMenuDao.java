package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class UserMenuDao extends DataObject {

	public UserMenuDao() {
		this.table = "TB_USER_MENU";
		this.PK = "USER_ID, MENU_ID";
	}
}