<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int eid = m.ri("eid");
String idx = m.rs("idx");
if(eid == 0 || courseId == 0 || "".equals(idx)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();

//정보
DataSet info = courseModule.query(
    "SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score, e.* "
    + " FROM " + courseModule.table + " a "
    + " INNER JOIN " + exam.table + " e ON a.module_id = e.id "
    + " WHERE a.status = 1 AND a.module = 'exam' "
    + " AND a.course_id = " + courseId + " AND a.module_id = " + eid + ""
);
if(!info.next()) { m.jsErrClose("해당 시험정보가 없습니다."); return; }

//목록
//examUser.d(out);
DataSet list = examUser.query(
    " SELECT a.* "
    + " FROM " + examUser.table + " a "
    + " INNER JOIN " + courseUser.table + " cu ON a.course_user_id = cu.id AND cu.status IN (1, 3) AND cu.course_id = " + courseId
    + " WHERE a.exam_id = " + eid + " AND a.course_user_id IN (" + idx + ") AND a.status = 1 AND a.submit_yn = 'Y' "
);
if(1 > list.size()) { m.jsErrClose("해당 응시정보가 없습니다."); return; }

//출력
p.setLayout("pop");
p.setBody("management.exam_user_print");
p.setVar("p_title", "시험결과출력");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,eid"));
p.setVar("form_script", f.getScript());

p.setVar("exam", info);

p.setLoop("list", list);
p.setVar("list_total", m.nf(list.size()));

p.display();

%>