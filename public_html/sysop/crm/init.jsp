<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

String ch = m.rs("ch", "crm");

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//제한
if(!isAuthCrm) { m.jsErrClose("접근이 거부 되었습니다."); return; }

//정보
DataSet uinfo = user.find("id = " + userId + " AND user_kind IN ('C', 'D', 'A', 'S') AND status = 1");
if(!uinfo.next()) { m.jsErrClose("접근이 거부 되었습니다."); return; }

//기본키
String uid = m.rs("uid");
if("".equals(uid)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//제한-소속운영자본인소속만
if("D".equals(userKind) && 1 > user.findCount("id = " + uid + " AND site_id = " + siteId + " AND dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") AND status != -1")) {
	m.jsErrClose("접근이 거부 되었습니다."); return;
}

if(!"".equals(siteinfo.s("pubtree_token"))) {
	p.setVar("ebook_block", true);
}

%>