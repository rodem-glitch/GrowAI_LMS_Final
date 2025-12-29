<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사(View) 데이터는 외부(e-poly)에서 내려오며, 실시간 API는 cnt 제한 때문에 누락이 발생할 수 있습니다.
//- 그래서 별도 동기화(`public_html/main/poly_sync.jsp`)로 우리 DB에 미리 저장하고, 여기서는 로컬 DB만 조회합니다.

String courseCode = m.rs("course_code");
if("".equals(courseCode)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_code가 필요합니다.");
	result.print();
	return;
}

String openYear = m.rs("open_year");
String openTerm = m.rs("open_term");
String bunbanCode = m.rs("bunban_code");
String groupCode = m.rs("group_code");
String keyword = m.rs("s_keyword");

PolyStudentDao polyStudent = new PolyStudentDao();
PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();
PolyMemberDao polyMember = new PolyMemberDao();
PolySyncLogDao polySyncLog = new PolySyncLogDao();

//미러 테이블이 없으면 안내 후 종료
try { polyStudent.findCount("1 = 0"); }
catch(Exception e) {
	result.put("rst_code", "5001");
	result.put("rst_message", "학사 미러 테이블이 없습니다. DB에 `public_html/ddl_poly_mirror.sql` 적용 후 /main/poly_sync.jsp를 실행해 주세요.");
	result.print();
	return;
}

ArrayList<Object> params = new ArrayList<Object>();
String where = " WHERE s.course_code = ? ";
params.add(courseCode);

if(!"".equals(openYear)) { where += " AND s.open_year = ? "; params.add(openYear); }
if(!"".equals(openTerm)) { where += " AND s.open_term = ? "; params.add(openTerm); }
if(!"".equals(bunbanCode)) { where += " AND s.bunban_code = ? "; params.add(bunbanCode); }
if(!"".equals(groupCode)) { where += " AND s.group_code = ? "; params.add(groupCode); }

if(!"".equals(keyword)) {
	where += " AND (s.member_key LIKE ? OR m.kor_name LIKE ? OR m.email LIKE ? OR m.mobile LIKE ?) ";
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
}

//왜: member_key 매칭 방식이 케이스별로 달라질 수 있어, 별칭 테이블을 거쳐 회원 정보로 조인합니다.
DataSet list = polyStudent.query(
	" SELECT "
	+ " s.member_key student_id "
	+ " , IFNULL(m.kor_name, '') name "
	+ " , IFNULL(m.email, '') email "
	+ " , IFNULL(m.mobile, '') mobile "
	+ " , s.visible, s.course_code, s.open_year, s.open_term, s.bunban_code, s.group_code "
	+ " FROM " + polyStudent.table + " s "
	+ " LEFT JOIN " + polyMemberKey.table + " mk ON mk.alias_key = s.member_key "
	+ " LEFT JOIN " + polyMember.table + " m ON m.member_key = mk.member_key "
	+ where
	+ " ORDER BY s.member_key ASC "
	, params.toArray()
);

String lastSync = "";
try { lastSync = polySyncLog.getOne("SELECT last_sync_date FROM " + polySyncLog.table + " WHERE sync_key = 'poly_mirror'"); }
catch(Exception ignore) {}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.put("rst_sync_date", lastSync);
result.print();

%>
