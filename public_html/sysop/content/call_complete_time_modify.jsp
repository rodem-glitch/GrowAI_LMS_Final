<%@ page contentType="application/json; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

Json resultData = new Json(out);

//기본키
int lessonId = m.ri("lid");
if(1 > lessonId) { result.put("rst_message", "기본키는 반드시 지정해야 합니다."); result.print(); return; }

//폼입력
int completeTime = m.ri("complete_time");

//객체
LessonDao lesson = new LessonDao();

//폼체크
f.addElement("complete_time", null, "hname:'인정시간', option:'number', min:'0'");

//등록
if(m.isPost() && f.validate()) {

	DataSet info = lesson.find("id = ? AND status != -1 AND site_id = ?", new Integer[] {lessonId, siteId});
	if(!info.next()) { result.put("rst_message", "해당 정보가 없습니다."); result.print(); return; }

	//처리
	lesson.item("complete_time", completeTime);
	if(!lesson.update("id = " + info.i("id"))) {
		result.put("rst_message", "수정하는 중 오류가 발생했습니다."); result.print(); return;
	}

	//출력
	resultData.put("complete_time_conv", m.nf(completeTime));

	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_data", resultData);
}

result.print();

%>