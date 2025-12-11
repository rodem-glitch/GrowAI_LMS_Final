package dao;

import malgnsoft.db.*;

public class ForumUserDao extends DataObject {

	public ForumUserDao() {
		this.table = "LM_FORUM_USER";
		this.PK = "forum_id,course_user_id";
	}
}