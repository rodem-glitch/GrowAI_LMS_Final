<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(79, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String courseNm = m.urldecode(m.rs("course_nm"));
if("".equals(courseNm)) { out.print("-1"); return; }

//객체
SubjectDao subject = new SubjectDao();

//subject.d(out);
//DataSet list = subject.find("status != -1 AND site_id = " + siteId, "id value, course_nm text", "course_nm ASC");
//out.print(list.serialize());

//중복검사
DataSet info = subject.find("course_nm = '" + courseNm + "'");
if(info.next()) { out.print(info.s("id")); return; }

//등록
int newId = subject.getSequence();
subject.item("id", newId);
subject.item("site_id", siteId);
subject.item("course_nm", f.get("course_nm"));
subject.item("reg_date", m.time("yyyyMMddHHmmss"));
subject.item("status", 1);
if(!subject.insert()) { out.print("-1"); return; }

out.print(newId + "");
return;

%>