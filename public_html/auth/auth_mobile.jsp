<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
if(!authYn) {
	m.jsError(_message.get("alert.auth.noservice_mobile"));
	return;
}

//객체
NiceID.Check.CPClient niceCheck = new  NiceID.Check.CPClient();

//변수
String sSiteCode = authCode;				// NICE로부터 부여받은 사이트 코드
String sSitePassword = authPasswd;		// NICE로부터 부여받은 사이트 패스워드

String sRequestNumber = "REQ0000000001";        	// 요청 번호, 이는 성공/실패후에 같은 값으로 되돌려주게 되므로
													// 업체에서 적절하게 변경하여 쓰거나, 아래와 같이 생성한다.
sRequestNumber = niceCheck.getRequestNO(sSiteCode);
session.setAttribute("REQ_SEQ" , sRequestNumber);	// 해킹등의 방지를 위하여 세션을 쓴다면, 세션에 요청번호를 넣는다.

String sAuthType = !"".equals(siteinfo.s("auth_type")) ? siteinfo.s("auth_type") : "M";      	// 없으면 기본 선택화면, M: 핸드폰, C: 신용카드, X: 공인인증서

String popgubun 	= "N";		//Y : 취소버튼 있음 / N : 취소버튼 없음
String customize 	= "";			//없으면 기본 웹페이지 / Mobile : 모바일페이지

// CheckPlus(본인인증) 처리 후, 결과 데이타를 리턴 받기위해 다음예제와 같이 http부터 입력합니다.
/*String sReturnUrl = request.getScheme() + "://" + siteinfo.s("domain") + "/auth/auth_mobile_success.jsp";      // 성공시 이동될 URL
String sErrorUrl = request.getScheme() + "://" + siteinfo.s("domain") + "/auth/auth_mobile_fail.jsp";          // 실패시 이동될 URL*/
String sReturnUrl = "https://" + siteinfo.s("domain") + "/auth/auth_mobile_success.jsp";      // 성공시 이동될 URL
String sErrorUrl = "https://" + siteinfo.s("domain") + "/auth/auth_mobile_fail.jsp";          // 실패시 이동될 URL

// 입력될 plain 데이타를 만든다.
String sPlainData = "7:REQ_SEQ" + sRequestNumber.getBytes().length + ":" + sRequestNumber +
					"8:SITECODE" + sSiteCode.getBytes().length + ":" + sSiteCode +
					"9:AUTH_TYPE" + sAuthType.getBytes().length + ":" + sAuthType +
					"7:RTN_URL" + sReturnUrl.getBytes().length + ":" + sReturnUrl +
					"7:ERR_URL" + sErrorUrl.getBytes().length + ":" + sErrorUrl +
					"11:POPUP_GUBUN" + popgubun.getBytes().length + ":" + popgubun +
					"9:CUSTOMIZE" + customize.getBytes().length + ":" + customize;

String sMessage = "";
String sEncData = "";

int iReturn = niceCheck.fnEncode(sSiteCode, sSitePassword, sPlainData);
if( iReturn == 0 )
{
	sEncData = niceCheck.getCipherData();
}
else if( iReturn == -1)
{
	sMessage = "암호화 시스템 에러입니다.";
}
else if( iReturn == -2)
{
	sMessage = "암호화 처리오류입니다.";
}
else if( iReturn == -3)
{
	sMessage = "암호화 데이터 오류입니다.";
}
else if( iReturn == -9)
{
	sMessage = "입력 데이터 오류입니다.";
}
else
{
	sMessage = "알수 없는 에러 입니다. iReturn : " + iReturn;
}
if(!"".equals(sMessage)) {
	out.print("<script>alert('" + sMessage + "\\n관리자에게 문의하세요.');</script>");
	return;
}

//세션-사용자변수
//mSession.put("auth_mobile_param_r1", m.rs("ch", ""));
//mSession.put("auth_mobile_param_r2", m.rs("mode", "join"));
//mSession.put("auth_mobile_param_r3", m.rs("returl", ""));
//mSession.save();

%>

<!doctype html>
<html>
<head>
	<script language='javascript'>
	window.name ="Parent_window";

	function fnPopup(){
		//if(!parent.goSubmit(parent.document.forms['form1'])) return;
		window.open('', 'popupChk', 'width=500, height=550, top=100, left=100, fullscreen=no, menubar=no, status=no, toolbar=no, titlebar=yes, location=no, scrollbar=no');
		document.form_chk.action = "https://nice.checkplus.co.kr/CheckPlusSafeModel/checkplus.cb";
		document.form_chk.target = "popupChk";
		document.form_chk.submit();
	}
	</script>
</head>
<body>
	<form name="form_chk" method="post">
	<input type="hidden" name="m" value="checkplusSerivce">
	<input type="hidden" name="EncodeData" value="<%= sEncData %>">
	<input type="hidden" name="param_r1" value="<%= m.rs("ch", "") %>">
	<input type="hidden" name="param_r2" value="<%= m.rs("mode", "join") %>">
	<input type="hidden" name="param_r3" value="<%= m.rs("returl", "") %>">
	</form>
</body>
</html>