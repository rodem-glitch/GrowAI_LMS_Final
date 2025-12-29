package dao;

import malgnsoft.db.*;

public class PolyMemberDao extends DataObject {

	public PolyMemberDao() {
		this.table = "LM_POLY_MEMBER";
		this.PK = "member_key";
	}
}

