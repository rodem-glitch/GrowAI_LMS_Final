<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    isErrorPage="true"

%><%@ include file="../common/sso_common.jsp" 
%><%

/*
인증서버에서 토큰 검증에 실패했을 때에 이 화면으로 리다이렉트된다.
relayState : 값이 존재하면 '돌아가기' 버튼을 누를 때에 해당 URL 로 이동
errCode : 토큰 검증 실패 관련 오류메시지
*/

String relayState = request.getParameter(RELAY_STATE_NAME);
String errCode = request.getParameter(FAILURE_CAUSE);

%><!DOCTYPE html>
<html>
<head>
<title> 일시적인 장애 </title>
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Cache-Control" content="no-cache">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0,maximum-scale=1.0">
<script type="text/javascript">
function doReturn() {
	var relay = "/";
<% if(relayState != null && !"".equals(relayState)) { %>
	relay = '<%= relayState %>';	
<% } %>
	location.href = relay;
	return;
}
</script>
<style type="text/css">
.bc-s-btnerror {
  height: 22px;
  line-height: 22px;
  position: relative;
  display: inline-block;
  text-decoration: none !important;
  border: 1px solid #cbcbcb;
  white-space: nowrap;
/*   background: url(../img/btn_mainbg.gif) repeat-x 0 top; */
  vertical-align: middle;
  overflow: visible;
  color: #363636;
/*   padding: 0px 11px 0px 11px; 
  background-position: left bottom; */
  cursor: pointer;
}

.bc-s-btnerror:hover {
  background: #e9e7e7;
  border-color: #d1d1d1;
}

.bc-s-btnLogin {
  height: 22px;
  line-height: 22px;
  position: relative;
  display: inline-block;
  text-decoration: none !important;
  border: 1px solid #cbcbcb;
  white-space: nowrap;
/*   background: url(../img/btn_mainbg.gif) repeat-x 0 top; */
  vertical-align: middle;
  overflow: visible;
  color: #363636;
/*   padding: 0px 11px 0px 11px; 
  background-position: left bottom; */
  cursor: pointer;
}

.bc-s-btnLogin:hover {
  background: #e9e7e7;
  border-color: #d1d1d1;
}
</style>
</head>
<body style="margin:2px;padding:0;font-size:12px;">

<div style="border: 1px solid #aaa;color: #222;padding: 15px 25px;overflow: hidden;line-height:18px;">
<!--   <h2 style="font-size:1.1em;border-bottom: 2px solid #f95e00;background: url(../img/icon_warning.gif) no-repeat left top;padding: 4px 0 6px 30px;">오류안내</h2> -->
  <h2 style="font-size:1.1em;border-bottom: 2px solid #f95e00;padding: 4px 0 6px 0px;">오류안내</h2>
  <p style="border: 1px solid #d3d3d3;background-color: #f3f3f3;color: #818181;padding:15px;">
    	죄송합니다. 서비스 처리중 오류가 발생하였습니다.
  </p>
  </p>
  <% if(errCode != null){ %>
  <p>
  <%= errCode %>
  </p>
  <% } %>
  <div style="text-align:right;padding-top: 10px;">
    <input class="bc-s-btnerror" id="previousPage" onclick="javascript:doReturn();" type="button" value="돌아가기"/>
  </div>
</div>

</body>
</html>