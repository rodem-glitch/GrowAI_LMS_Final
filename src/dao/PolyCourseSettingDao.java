package dao;

import malgnsoft.db.*;

public class PolyCourseSettingDao extends DataObject {

	public PolyCourseSettingDao() {
		// 왜: 학사 과목의 운영 설정/목차/시험은 별도 테이블에 저장합니다.
		this.table = "LM_POLY_COURSE_SETTING";
		this.PK = "site_id,course_code,open_year,open_term,bunban_code,group_code";
		// 왜: DataObject 기본값(PK=id + useSeq=Y) 상태면 INSERT 시 자동으로 id 컬럼을 넣으려다 오류가 날 수 있어 차단합니다.
		this.useSeq = "N";
	}
}
