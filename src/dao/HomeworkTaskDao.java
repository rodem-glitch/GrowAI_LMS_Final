package dao;

import malgnsoft.db.*;

public class HomeworkTaskDao extends DataObject {

	public HomeworkTaskDao() {
		// 기존 LM_HOMEWORK_USER는 (homework_id, course_user_id)로 1건만 저장할 수 있어서,
		// 학생별 추가 과제/피드백을 횟수 제한 없이 누적 기록하려고 별도 테이블을 둡니다.
		this.table = "LM_HOMEWORK_TASK";
		this.PK = "id";
	}
}

