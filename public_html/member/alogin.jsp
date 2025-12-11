<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String id = m.rs("id");
String ek = m.rs("ek");
if("".equals(id) || "".equals(id)) return;

//폼입력
String retUrl = m.rs("retUrl", "../main/index.jsp");

//제한
String eKey = m.encrypt(id + "_" + m.time("yyyyMMdd") + "_LMSLOGIN2014", "SHA-256");
if(!eKey.equals(ek)) return;

//객체
UserDao user = new UserDao();
GroupDao group = new GroupDao();
UserLoginDao userLogin = new UserLoginDao();

//정보
DataSet info = user.find("login_id = '" + id + "' AND site_id = " + siteId + " AND status IN (1, 30)");
if(!info.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }

//로그인
String tmpGroups = group.getUserGroup(info);

auth.put("ID", info.s("id"));
auth.put("LOGINID", info.s("login_id"));
auth.put("KIND", info.s("user_kind"));
auth.put("NAME", info.s("user_nm"));
auth.put("EMAIL", info.s("email"));
auth.put("MOBILE", info.s("mobile"));
auth.put("BIRTHDAY", info.s("birthday"));
auth.put("GENDER", info.s("gender"));
auth.put("DEPT", info.i("dept_id"));
auth.put("SESSIONID", "SYSLOGIN");
auth.put("GROUPS", tmpGroups);
auth.put("GROUPS_DISC", group.getMaxDiscRatio());
auth.put("TUTOR_YN", "Y".equals(info.s("tutor_yn")) ? "Y" : "N");
auth.put("LOGINMETHOD", "SYSLOGIN");
auth.put("USER_AUTH2_YN", "Y");
auth.put("USER_AUTH2_TYPE", "");
//auth.put("ALOGIN_YN", "Y");
auth.setAuthInfo();

//로그
userLogin.item("id", userLogin.getSequence());
userLogin.item("site_id", siteId);
userLogin.item("user_id", info.i("id"));
userLogin.item("admin_yn", "N");
userLogin.item("login_type", "I");
userLogin.item("ip_addr", userIp);
userLogin.item("agent", request.getHeader("user-agent"));
userLogin.item("device", userLogin.getDeviceType(request.getHeader("user-agent")));
userLogin.item("log_date", m.time("yyyyMMdd"));
userLogin.item("reg_date", m.time("yyyyMMddHHmmss"));
if(!userLogin.insert()) {}

m.jsReplace(retUrl, "parent");
return;

%>