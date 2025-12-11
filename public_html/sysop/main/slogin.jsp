<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
String uid = m.rs("uid");
String ek = m.rs("ek");
String returl = m.rs("returl");
if("".equals(uid) || "".equals(ek)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//암호키
if(!m.md5("SEK" + uid + m.time("yyyyMMdd")).equals(ek)) {
	m.jsErrClose("올바른 접근이 아닙니다."); return;
}

//객체
UserDao user = new UserDao();
UserLoginDao userLogin = new UserLoginDao();
GroupDao group = new GroupDao();
CourseManagerDao courseManager = new CourseManagerDao();

//정보
DataSet info = user.find("id = '" + uid + "' AND site_id = " + siteId + " AND user_kind IN ('C', 'D', 'A', 'S') AND status = 1");
if(!info.next()) { m.jsErrClose("회원 정보가 없습니다."); return; }

//인증
auth.put("ID", info.i("id"));
auth.put("LOGINID", info.s("login_id"));
auth.put("KIND", info.s("user_kind"));
auth.put("NAME", info.s("user_nm"));
auth.put("DEPT", info.i("dept_id"));
auth.put("GROUPS", group.getUserGroup(info));
auth.put("MANAGE_COURSES", courseManager.getManageCourses(info.i("id")));
//auth.put("SESSIONID", ssinfo.s("id"));
auth.put("SESSIONID", "SYSLOGIN");
auth.setAuthInfo();

//로그
String addr = m.getRemoteAddr().substring(0, 10);
if(!"115.91.52.".equals(addr)) {
	userLogin.item("id", userLogin.getSequence());
	userLogin.item("site_id", siteId);
	userLogin.item("user_id", info.i("id"));
	userLogin.item("admin_yn", "Y");
	userLogin.item("login_type", "I");
	userLogin.item("ip_addr", userIp);
	userLogin.item("agent", request.getHeader("user-agent"));
	userLogin.item("device", userLogin.getDeviceType(request.getHeader("user-agent")));
	userLogin.item("log_date", m.time("yyyyMMdd"));
	userLogin.item("reg_date", m.time("yyyyMMddHHmmss"));
	if(!userLogin.insert()) { }
}

m.jsReplace("".equals(returl) ? "../index.jsp" : returl);

%>