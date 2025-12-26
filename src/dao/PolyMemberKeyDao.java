package dao;

import malgnsoft.db.*;

public class PolyMemberKeyDao extends DataObject {

	public PolyMemberKeyDao() {
		this.table = "LM_POLY_MEMBER_KEY";
		this.PK = "alias_key";
	}
}

