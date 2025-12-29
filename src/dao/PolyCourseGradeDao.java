package dao;

import malgnsoft.db.*;

public class PolyCourseGradeDao extends DataObject {

	public PolyCourseGradeDao() {
		// 왜: 학사 과목 성적(A/B/C/D/F)을 학생별로 저장합니다.
		this.table = "LM_POLY_COURSE_GRADE";
		this.PK = "site_id,course_code,open_year,open_term,bunban_code,group_code,member_key";
		// 왜: DataObject 기본값(PK=id + useSeq=Y) 상태면 INSERT 시 자동으로 id 컬럼을 넣으려다 오류가 날 수 있어 차단합니다.
		this.useSeq = "N";
	}
}
