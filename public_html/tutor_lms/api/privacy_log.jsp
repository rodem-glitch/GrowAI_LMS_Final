<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜: 교수자 LMS에서 개인정보 조회/다운로드 사유를 기록하기 위해 별도 로그를 남깁니다.

String logType = m.rs("log_type", "V"); // V=조회, E=엑셀
String purpose = m.rs("purpose");
String pageNm = m.rs("page_nm", "수강생 정보");
int courseId = m.ri("course_id");
String userIdsRaw = m.rs("user_ids");
int userCnt = m.ri("user_cnt");

if("".equals(purpose)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "사유가 필요합니다.");
	result.print();
	return;
}

// 권한: 교수자는 본인 과목(주강사)만, 관리자는 전체
if(courseId > 0 && !isAdmin) {
	CourseTutorDao courseTutor = new CourseTutorDao();
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 개인정보를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

InfoLogDao infoLog = new InfoLogDao(siteId);
String pagePath = request.getRequestURI() + (!"".equals(m.qs()) ? "?" + m.qs() : "");
infoLog.setItems(userId, "T", pagePath, userIp);

DataSet list = null;
if(!"".equals(userIdsRaw)) {
	DataSet temp = new DataSet();
	String[] ids = m.split(",", userIdsRaw);
	if(ids != null) {
		for(String idStr : ids) {
			int uid = m.parseInt(idStr);
			if(uid > 0) {
				temp.addRow();
				temp.put("user_id", uid);
			}
		}
	}
	if(temp.size() > 0) list = temp;
}

int logId = infoLog.add(logType, pageNm, userCnt, purpose, list);

if(logId == 0) {
	result.put("rst_code", "5001");
	result.put("rst_message", "로그 저장에 실패했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", logId);
result.print();

%>
