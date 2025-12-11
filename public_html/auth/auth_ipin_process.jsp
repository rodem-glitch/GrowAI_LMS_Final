<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

	//제한
	if(!ipinYn) {
		m.jsError(_message.get("alert.auth.noservice_ipin"));
		return;
	}

	/*********************************************************************************************
		NICE평가정보 Copyright(c) KOREA INFOMATION SERVICE INC. ALL RIGHTS RESERVED
		
		서비스명 : 가상주민번호서비스 (IPIN) 서비스
		페이지명 : 가상주민번호서비스 (IPIN) 사용자 인증 정보 처리 페이지
		
				   수신받은 데이터(인증결과)를 메인화면으로 되돌려주고, close를 하는 역활을 합니다.
	**********************************************************************************************/
	
	// 사용자 정보 및 CP 요청번호를 암호화한 데이타입니다. (ipin_main.jsp 페이지에서 암호화된 데이타와는 다릅니다.)
	String sResponseData = requestReplace(request.getParameter("enc_data"), "encodeData");
	
	// ipin_main.jsp 페이지에서 설정한 데이타가 있다면, 아래와 같이 확인가능합니다.
	/*
	String sReservedParam1  = requestReplace(request.getParameter("param_r1"), "");
	String sReservedParam2  = requestReplace(request.getParameter("param_r2"), "");
	String sReservedParam3  = requestReplace(request.getParameter("param_r3"), "");
	String sReservedParam1 = mSession.s("auth_ipin_param_r1");
	String sReservedParam2 = mSession.s("auth_ipin_param_r2");
	String sReservedParam3 = mSession.s("auth_ipin_param_r3");
	*/
	String sReservedParam1 = "";
	String sReservedParam2 = "";
	String sReservedParam3 = "";
    
    // 암호화된 사용자 정보가 존재하는 경우
    if (!sResponseData.equals("") && sResponseData != null)
    {

%>

<!doctype html>
<html>
<head>
	<meta charset="utf-8">
	<script language='javascript'>
	function fnLoad()
	{
		var el = parent.opener.parent.document.getElementById("checkplusAuthIpin");
		var elDoc = el.contentWindow || el.contentDocument;
		var f = elDoc.vnoform;
		f.enc_data.value = "<%= sResponseData %>";
		
		/*
		f.param_r1.value = "<%= sReservedParam1 %>";
		f.param_r2.value = "<%= sReservedParam2 %>";
		f.param_r3.value = "<%= sReservedParam3 %>";
		*/

		f.target = "Parent_window";
	
		f.action = "../auth/auth_ipin_result.jsp";
		f.submit();
		
		self.close();
	}
	</script>
</head>
<body onLoad="fnLoad()">

<%
	} else {
%>

<html>
<head>
	<meta charset="utf-8">
</head>
<body onLoad="self.close()">

<%
	}
%>
<%!
public String requestReplace (String paramValue, String gubun) {
        String result = "";
        
        if (paramValue != null) {
        	
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
        	
        	if(gubun != "encodeData"){
        		paramValue = paramValue.replaceAll("\\+", "");
        		paramValue = paramValue.replaceAll("/", "");
            paramValue = paramValue.replaceAll("=", "");
        	}
        	
        	result = paramValue;
            
        }
        return result;
  }
%>
</body>
</html>