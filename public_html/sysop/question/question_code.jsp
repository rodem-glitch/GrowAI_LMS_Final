<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();

//카테고리
DataSet categories = category.getList(siteId);

//파일
String filename = "문제등록코드표(" + m.time("yyyy-MM-dd") + ").xls";
filename = new String(filename.getBytes("KSC5601"), "8859_1");
response.setContentType("application/vnd.ms-excel; charset=euc-kr");
response.setHeader("Content-Disposition", "attachment; filename=" + filename);
PrintWriter logger = new PrintWriter(response.getOutputStream(), true);


//출력
p.setLoop("grades", m.arr2loop(question.grades));
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("categories", categories);

logger.write(p.fetch("../html/question/question_code.html"));
logger.close();


%>