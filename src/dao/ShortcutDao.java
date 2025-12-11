package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class ShortcutDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] targets = { "_blank=>새 창 띄움 (_blank)", "_Main=>관리자 창에 띄움 (_Main)" };
	public String[] types = { "U=>개인", "S=>전체" };
	
	public String[] statusListMsg = { "1=>list.shortcut.status_list.1", "0=>list.shortcut.status_list.0" };
	public String[] targetsMsg = { "_blank=>list.shortcut.targets._blank", "_Main=>list.shortcut.targets._Main" };
	public String[] typesMsg = { "U=>list.shortcut.types.U", "S=>list.shortcut.types.S" };

	private int siteId = 0;

	public ShortcutDao() {
		this.table = "TB_SHORTCUT";
		this.PK = "id";
	}

	public ShortcutDao(int siteId) {
		this.table = "TB_SHORTCUT";
		this.PK = "id";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public int autoSort(int userId) {
		DataSet list = this.find("site_id = " + this.siteId + " AND user_id = " + userId + " AND status != -1", "id, sort", "sort ASC, id ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE id = " + list.s("id") + " AND status != -1");
			sort++;
		}
		return 1;
	}

}