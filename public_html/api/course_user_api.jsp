<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String completeYn = m.rs("complete").toUpperCase();
String sdate = m.time("yyyyMMdd", m.rs("sdate"));
String edate = m.time("yyyyMMdd", m.rs("edate"));
String status = m.rs("status");
String sLoginId = m.rs("login_id");
int cid = m.ri("cid");
int uid = m.ri("uid");
//if(!error && ((!"".equals(completeYn) && !"Y".equals(completeYn) && !"N".equals(completeYn)) || "".equals(sdate) || "".equals(edate))) {
//	_ret.put("ret_code", "310");
//	_ret.put("ret_msg", "not valid information");
//	error = true;
//}

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//목록
DataSet list = null;
if(!error) {
	ArrayList<String> qs = new ArrayList<String>();
	qs.add(sdate + "000000");
	qs.add(edate + "235959");
	if(cid > 0) qs.add(cid + "");
	if(uid > 0) qs.add(uid + "");
	if(!"".equals(sLoginId)) qs.add(sLoginId);
	if(!"".equals(completeYn)) qs.add(completeYn);
	if(!"".equals(status)) qs.add(status);
	
	//courseUser.d(out);
	list = courseUser.query(
		" SELECT a.id, a.course_id, c.year, c.step, c.course_nm, a.user_id, u.login_id, u.user_nm "
		+ " , a.start_date, a.end_date, a.credit, a.total_score, a.progress_ratio, a.complete_yn, a.complete_no, a.complete_date, a.status "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status != -1 "
		+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1"
		+ " WHERE a.reg_date >= ? AND a.reg_date <= ? "
		+ (cid > 0 ? " AND a.course_id = ? " : "")
		+ (uid > 0 ? " AND a.user_id = ? " : "")
		+ (!"".equals(sLoginId) ? " AND u.login_id = ? " : "")
		+ (!"".equals(completeYn) ? " AND a.complete_yn = ? " : "")
		+ (!"".equals(status) ? " AND a.status = ? " : "")
		+ " AND a.site_id = " + siteId + " AND a.status != -1 "
		, qs.toArray()
	);
	_ret.put("ret_size", list.size());
}

//수정
if(!apiLog.updateLog(_ret.get("ret_code").toString())) {
	_ret.put("ret_code", "-1");
	_ret.put("ret_msg", "cannot modify db");
	list = null;
	error = true;
};

//출력
apiLog.printList(out, _ret, list);
%>