<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FreepassDao freepass = new FreepassDao(siteId);
FreepassCourseDao freepassCourse = new FreepassCourseDao(siteId);
CourseDao course = new CourseDao();

//기본키
int id = m.ri("fid");
if(id == 0) return;

//정보
DataSet info = freepass.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) return;

//갱신
String[] idx = f.get("ct_idx").split(",");
if(idx != null) freepass.item("categories", "|" + m.join("|", idx) + "|");
if(!freepass.update("id = " + id)) return;

//과정수
int courseCnt = course.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + course.table + " a "
	+ " WHERE "
	+ (!"".equals(f.get("ct_idx")) ? " a.status = 1 AND ( a.category_id IN (" + f.get("ct_idx") + ") OR " : " ( a.status = 1 AND ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + freepassCourse.table + " "
		+ " WHERE freepass_id = " + id + " AND add_type = 'A' "
		+ " AND course_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + freepassCourse.table + " "
		+ " WHERE freepass_id = " + id + " AND add_type = 'D' "
		+ " AND course_id = a.id "
	+ " ) "
);

out.print(m.nf(courseCnt));

%>