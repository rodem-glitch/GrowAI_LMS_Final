package dao;

import malgnsoft.db.*;

/**
 * 왜 필요한가:
 * - `project`(React) 화면의 과정개설/운영계획서에는 LM_SUBJECT에 없는 상세 입력값이 많습니다.
 * - 그래서 과정 1건(SUBJECT_ID)당 1건으로 JSON(PLAN_JSON)을 저장하는 보조 테이블을 사용합니다.
 * - 기존 레거시 패턴(DataObject 상속)을 그대로 따릅니다.
 */
public class SubjectPlanDao extends DataObject {

	public SubjectPlanDao() {
		this.table = "LM_SUBJECT_PLAN";
		this.PK = "subject_id";
	}
}

