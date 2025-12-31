package dao;

import malgnsoft.db.*;

public class PolyProfessorDao extends DataObject {

	public PolyProfessorDao() {
		this.table = "LM_POLY_PROFESSOR";
		this.PK = "member_key";
	}
}
