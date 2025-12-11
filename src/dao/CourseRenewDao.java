package dao;

import malgnsoft.db.*;

public class CourseRenewDao extends DataObject {

	public String[] types = { "C=>수강등록", "D=>입금확인", "R=>연장결제", "S=>관리자수정", "U=>과정수정", "F=>수강승인", "N=>미지정" };

	public CourseRenewDao() {
		this.table = "LM_COURSE_RENEW";
		this.PK = "id";
	}

}