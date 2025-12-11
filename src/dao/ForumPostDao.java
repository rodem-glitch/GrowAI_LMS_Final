package dao;

import malgnsoft.db.*;

public class ForumPostDao extends DataObject {

	public ForumPostDao() {
		this.table = "LM_FORUM_POST";
		this.PK = "id";
	}
	public void updateHitCount(int id) {
		execute("UPDATE " + this.table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	}
}