<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
if(!authYn) {
	m.jsError(_message.get("alert.auth.noservice_mobile"));
	return;
}

//객체
UserDao user = new UserDao();
NiceID.Check.CPClient niceCheck = new NiceID.Check.CPClient();

//변수
String sEncodeData = requestReplace(request.getParameter("EncodeData"), "encodeData");
String sReserved1  = requestReplace(request.getParameter("param_r1"), "");
String sReserved2  = requestReplace(request.getParameter("param_r2"), "");
String sReserved3  = m.rs("param_r3");
//String sReserved1 = mSession.s("auth_mobile_param_r1");
//String sReserved2 = mSession.s("auth_mobile_param_r2");
//String sReserved3 = mSession.s("auth_mobile_param_r3");

String sSiteCode = authCode;		// NICE로부터 부여받은 사이트 코드
String sSitePassword = authPasswd;	// NICE로부터 부여받은 사이트 패스워드

String sCipherTime = "";			// 복호화한 시간
String sRequestNumber = "";			// 요청 번호
String sResponseNumber = "";		// 인증 고유번호
String sAuthType = "";				// 인증 수단
String sName = "";					// 성명
String sDupInfo = "";				// 중복가입 확인값 (DI_64 byte)
String sConnInfo = "";				// 연계정보 확인값 (CI_88 byte)
String sBirthDate = "";				// 생일
String sGender = "";				// 성별
String sNationalInfo = "";			// 내/외국인정보 (개발가이드 참조)
String sMobileNo = "";				// 휴대폰번호
String sMobileCo = "";				// 통신사
String sMessage = "";
String sPlainData = "";

int iReturn = niceCheck.fnDecode(sSiteCode, sSitePassword, sEncodeData);

//복호화
if(iReturn == 0) {
	sPlainData = niceCheck.getPlainData();
	sCipherTime = niceCheck.getCipherDateTime();
	
	// 데이타를 추출합니다.
	java.util.HashMap mapresult = niceCheck.fnParse(sPlainData);
	
	sRequestNumber  = (String)mapresult.get("REQ_SEQ");
	sResponseNumber = (String)mapresult.get("RES_SEQ");
	sAuthType 		= (String)mapresult.get("AUTH_TYPE");
	sName 			= (String)mapresult.get("NAME");
	sBirthDate 		= (String)mapresult.get("BIRTHDATE");
	sGender 		= (String)mapresult.get("GENDER");
	sNationalInfo  	= (String)mapresult.get("NATIONALINFO");
	sDupInfo 		= (String)mapresult.get("DI");
	sConnInfo 		= (String)mapresult.get("CI");
	sMobileCo 		= (String)mapresult.get("MOBILE_CO");
	sMobileNo 		= (String)mapresult.get("MOBILE_NO");
	
	String session_sRequestNumber = (String)session.getAttribute("REQ_SEQ");
	if(!sRequestNumber.equals(session_sRequestNumber)) {
		sMessage = "세션값이 다릅니다. 올바른 경로로 접근하시기 바랍니다.";
		sResponseNumber = "";
		sAuthType = "";
	}
} else {
	m.jsErrClose(_message.get("alert.auth.error_with_code", new String[] {"code=>S" + iReturn}));
	return;
}

if("login".equals(sReserved2)) { //로그인
	//정보
	DataSet info = user.find("dupinfo = '" + sDupInfo + "' AND site_id = " + siteId + "");
	if(info.next()) {
		//변수
		String sslDomain = request.getServerName().indexOf(".malgn.co.kr") > 0 ? "ssl.malgn.co.kr" : "ssl.malgnlms.com";
		if(siteinfo.b("ssl_yn")) sslDomain = siteinfo.s("domain");

		//세션
		mSession.put("login_method", "auth-" + sAuthType);
		mSession.save();

		//로그인
		String accessToken = m.md5(m.getUniqId());
		String ek = m.encrypt(accessToken + sslDomain + m.time("yyyyMMdd"));
		user.item("access_token", accessToken);
		if(!user.update("id = " + info.i("id") + " AND site_id = " + siteId)) {
			m.jsErrClose(_message.get("alert.member.error_find"));
			return;
		}
		m.jsReplace("../" + (!m.isMobile() ? "member" : "mobile") + "/login.jsp?returl=" + m.urlencode(sReserved3) + "&access_token=" + accessToken + "&ek=" + ek, "opener");
		m.js("window.close();");
		return;
	} else {
		m.jsErrClose(_message.get("alert.member.nodata"));
		return;
	}

//} else if("join".equals(sReserved2)) { //가입
} else {
	//세션
	mSession.put("sName", null != sName ? sName : "");					// 이름
	mSession.put("sDupInfo", null != sDupInfo ? sDupInfo : "");				// 중복가입 확인값 (DI - 64 byte 고유값)
	mSession.put("sGenderCode", null != sGender ? sGender : "");			// 성별 코드 (개발 가이드 참조)
	mSession.put("sBirthDate", null != sBirthDate ? sBirthDate : "");			// 생년월일 (YYYYMMDD)
	mSession.put("sNationalInfo", null != sNationalInfo ? sNationalInfo : "");	// 내/외국인 정보 (개발 가이드 참조)
	mSession.put("sMobileCo", null != sMobileCo ? sMobileCo : "");	// 통신사
	mSession.put("sMobileNo", null != sMobileNo ? sMobileNo : "");	// 휴대폰번호
	mSession.save();

	//이동
	String key = m.getUniqId();
	String ek = m.encrypt(key + "_AGREE");

//	m.jsReplace("../" + (!"mobile".equals(sReserved1) ? "member" : "mobile") + "/join.jsp?ek=" + ek + "&k=" + key, "opener.parent");
//	out.print("<script>opener.parent.authSuccess('" + sDupInfo + "', '" + sResponseNumber + "', '" + m.time("yyyy-MM-dd HH:mm:ss") + "');window.close();</script>");
	out.print("<script>opener.parent.authSuccess();window.close();</script>");
}

out.print("<script>self.close();</script>");

%>
<%!
public String requestReplace(String paramValue, String gubun) {
	String result = "";
	if(paramValue != null) {
		paramValue = paramValue.replaceAll("<", "&lt;").replaceAll(">", "&gt;");

		paramValue = paramValue.replaceAll("\\*", "");
		paramValue = paramValue.replaceAll("\\?", "");
		paramValue = paramValue.replaceAll("\\[", "");
		paramValue = paramValue.replaceAll("\\{", "");
		paramValue = paramValue.replaceAll("\\(", "");
		paramValue = paramValue.replaceAll("\\)", "");
		paramValue = paramValue.replaceAll("\\^", "");
		paramValue = paramValue.replaceAll("\\$", "");
		paramValue = paramValue.replaceAll("'", "");
		paramValue = paramValue.replaceAll("@", "");
		paramValue = paramValue.replaceAll("%", "");
		paramValue = paramValue.replaceAll(";", "");
		paramValue = paramValue.replaceAll(":", "");
		paramValue = paramValue.replaceAll("-", "");
		paramValue = paramValue.replaceAll("#", "");
		paramValue = paramValue.replaceAll("--", "");
		paramValue = paramValue.replaceAll("-", "");
		paramValue = paramValue.replaceAll(",", "");
		
		if(gubun != "encodeData") {
			paramValue = paramValue.replaceAll("\\+", "");
			paramValue = paramValue.replaceAll("/", "");
			paramValue = paramValue.replaceAll("=", "");
		}
		result = paramValue;
	}
	return result;
}
%>