package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class SiteMenuDao extends DataObject {

	public SiteMenuDao() {
		this.table = "TB_SITE_MENU";
		this.PK = "SITE_ID, MENU_ID";
	}
}