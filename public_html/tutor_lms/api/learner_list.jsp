<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목개설(CreateSubjectWizard)에서 "학습자 선택"은 샘플 배열이 아니라 실제 회원(TB_USER) 목록을 검색해 보여줘야 합니다.
//- 한 번에 너무 많은 회원을 내려주면 느려질 수 있으니, 검색/필터 + 페이지 제한(limit)을 같이 지원합니다.

UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

String keyword = m.rs("s_keyword").trim();
String deptKeyword = m.rs("s_dept").trim(); //부서명(선택) - 화면 필터용
int deptId = m.ri("dept_id");              //부서 ID(선택)

int page = m.ri("page");
int limit = m.ri("limit");
if(page <= 0) page = 1;
if(limit <= 0) limit = 50;
if(limit > 200) limit = 200; //왜: 너무 큰 limit은 DB/서버에 부담이 됩니다.
int offset = (page - 1) * limit;

ArrayList<Object> params = new ArrayList<Object>();
String where = " u.site_id = " + siteId + " AND u.status = 1 AND u.user_kind = 'U' ";

//검색(이름/아이디/이메일)
if(!"".equals(keyword)) {
	where += " AND (u.user_nm LIKE ? OR u.login_id LIKE ? OR u.email LIKE ?) ";
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
}

//부서 필터
if(deptId > 0) {
	where += " AND u.dept_id = ? ";
	params.add(deptId);
} else if(!"".equals(deptKeyword)) {
	//왜: 사이트마다 부서 구조가 다르므로, 우선은 "부서명 포함"으로 가장 단순하게 제공합니다.
	where += " AND d.dept_nm LIKE ? ";
	params.add("%" + deptKeyword + "%");
}

//왜: 캠퍼스/전공 같은 상세 필드는 사이트마다 컬럼이 다를 수 있어, 여기서는 "부서 경로"로 대체합니다.
//- dept_path: "본부 > 캠퍼스 > 학과"처럼 계층이 있으면 전체 경로를 내려줍니다.
DataSet deptData = null;
try {
	deptData = userDept.find("site_id = " + siteId + " AND status = 1", "id,parent_id,dept_nm,depth,sort", "depth ASC, sort ASC");
	userDept.setData(deptData);
} catch(Exception ignore) {}

DataSet list = user.query(
	" SELECT u.id, u.login_id, u.user_nm, u.email, u.dept_id "
	+ " , d.dept_nm "
	+ " FROM " + user.table + " u "
	+ " LEFT JOIN " + userDept.table + " d ON d.id = u.dept_id AND d.site_id = " + siteId + " AND d.status = 1 "
	+ " WHERE " + where
	+ " ORDER BY u.id DESC "
	+ " LIMIT " + offset + ", " + limit
	, params.toArray()
);

while(list.next()) {
	list.put("id", list.i("id"));
	list.put("name", list.s("user_nm"));
	list.put("student_id", list.s("login_id"));
	list.put("email", list.s("email"));

	int did = list.i("dept_id");
	String deptPath = "";
	try { if(did > 0) deptPath = userDept.getTreeNames(did); } catch(Exception ignore) {}
	list.put("dept_path", deptPath);
	list.put("dept_nm", !"".equals(list.s("dept_nm")) ? list.s("dept_nm") : "-");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

