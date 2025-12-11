package dao;

import malgnsoft.db.*;

public class MenuLocaleDao extends DataObject {

	private String locale = "default";

	public MenuLocaleDao() {
		this.table = "TB_MENU_LOCALE";
	}

	public MenuLocaleDao(String locale) {
		this.table = "TB_MENU_LOCALE";
		this.locale = locale;
	}

	public String getName(int menuId, String v) {
		String result = this.getOne("SELECT menu_locale_nm FROM " + this.table + " WHERE menu_id = " + menuId + " AND locale_cd = '" + this.locale + "'");
		return !"".equals(result) ? result : v;
	}
}