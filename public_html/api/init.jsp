<%@ include file="/init.jsp"%><%@ page import="org.json.*" %>
<%@ page import="java.util.Base64" %><%
// kollus channel
String ch = "sysop";

//JSON
JSONObject _ret = new JSONObject();
_ret.put("ret_code", "000");
_ret.put("ret_msg", "success");

//변수
boolean error = false;
String token = m.rs("token").replace(" ","+"); //.toLowerCase();
String format = m.rs("format", "json").toLowerCase();

//객체
ApiLogDao apiLog = new ApiLogDao(format, request, response);

//등록
if(!apiLog.insertLog(siteId, m.qs())) {
	_ret.put("ret_code", "210");
	_ret.put("ret_msg", "cannot insert db");
	apiLog.printList(out, _ret);
	return;
}
/*
//POST전용
if(!error && !m.isPost()) {
	_ret.put("ret_code", "220");
	_ret.put("ret_msg", "not valid method");
	error = true;
}
*/

//토큰
Aes256 aes = new Aes256();
if (aes.isBase64(token)) { // 외부 호출 토큰 인지 확인
	token = aes.decrypt(token);
}


if(!error && ("".equals(siteinfo.s("api_token")) || !token.equals(siteinfo.s("api_token")))) {
	_ret.put("ret_code", "230");
	_ret.put("ret_msg", "not valid api token");
	error = true;
}

//사용량
if(!error && siteinfo.i("api_limit")
	<= apiLog.getOneInt(
		"SELECT COUNT(*) FROM " + apiLog.table + " WHERE site_id = " + siteId
		+ " AND reg_date >= '" + m.time("yyyyMM01000000") + "' AND reg_date <= '" + m.time("yyyyMMddHHmmss") + "' AND return_code = '000'")
	) {
	_ret.put("ret_code", "240");
	_ret.put("ret_msg", "api limit");
	error = true;
}

if(!error && !"".equals(siteinfo.s("api_ip_addr"))) {
	String clientIP = userIp;
	String[] ipArr = m.split("|", siteinfo.s("api_ip_addr") + "|106.248.195.135|115.91.52.203");
	boolean ipAuth = false;

	for(int i = 0; i < ipArr.length; i++) {
		if(ipArr[i].endsWith("*")) ipAuth = clientIP.startsWith(ipArr[i].replace("*", ""));
		else ipAuth = clientIP.equals(ipArr[i]);

		if(ipAuth) break;
	}

	if(!ipAuth) {
		_ret.put("ret_code", "250");
		_ret.put("ret_msg", "unauthorized ip address");
		error = true;
	}
}
%>