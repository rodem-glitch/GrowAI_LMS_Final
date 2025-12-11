<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%@ include file="../include/sso_entry.jsp" 
%><!DOCTYPE html><html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

<style type="text/css">

body {
  font-family:'Malgun Gothic';
  font-size:10pt; 
}

table {
  width:80%;
  margin:auto;
  text-align:left;
}

table, th {
  border: 1px solid gray;
  border-collapse:collapse;
  text-align:center;
  padding: 5px;
}

table, td {
  border: 1px solid gray;
  border-collapse:collapse;
  text-align:left;
  padding: 5px;
}

table .first{
  width:20%;
}
table .second{
  width:80%;
}
p {
  margin: 0px;
}
.font_bold {
  font-weight: bold;
}

</style>
</head>
<body>

<h2>eXSignOnUserId : <%= eXSignOnUserId %></h2>

<p>
<hr>
<p>
<% 
if(SSO_SESSION_ANONYMOUSE.equals(eXSignOnUserId)) {
%>
  <h4>eXSignOnUserId 값이 anonymous일 경우 로그인되지 않은 사용자</h4>
<%
} else {
%>
  <h4>eXSignOnUserId 값이 anonymous가 아닐 경우 SSO를 통해 획득한 사용자 정보가 출력</h4>
<%
}
%>
<p>
<hr>
<p>

<% 
if(SSO_SESSION_ANONYMOUSE.equals(eXSignOnUserId)) {
%>

<table>
  <colgroup>
    <col class="first">
    <col class="second">
  </colgroup>
  <tr>
    <th colspan="2">통합로그인 페이지를 이용한 로그인</th>
  </tr>
  <tr>
    <td>설명</td>
    <td>
      <p>&nbsp;통합로그인 페이지를 이용하여 로그인 하는 경우 로그인 안된 사용자가 인증서버로 로그인 확인 요청 시 통합 로그인 페이지로 이동하여 로그인을 유도 할 수 있다.</p>
      <p>&nbsp;로그인 되어 있거나 로그인에 성공한 경우 Token을 발급 하여 SP로 Redirect 된다.</p>
    </td> 
  </tr>
  <tr>
    <td>요청 URL</td>
    <td>&nbsp;/sso/sso_idp_login.jsp</td> 
  </tr>
  <tr>
    <td>파라미터</td>
    <td>
<p>* <span class="font_bold">RelayState</span> (옵션) : 모든 SSO 인증 절차를 거친 후 이동 할 URL 지정. RelayState가 없을 경우 SP 시스템의 Context path 요청</p>
    </td> 
  </tr>
  <tr>
    <td>샘플 코드</td>
    <td>
<p>&lt;form id=&quot;idpLoginFrm&quot; name=&quot;idpLoginFrm&quot; method=&quot;post&quot; action=&quot;../sso/sso_idp_login.jsp&quot;&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;hidden&quot; name=&quot;<%= RELAY_STATE_NAME %>&quot; value=&quot;<%= addContextPath(request, "/exsignon/sample/main.jsp") %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input  value=&quot;통합 로그인 요청&quot; type=&quot;submit&quot; /&gt;</p>
<p>&lt;/form&gt;</p>
    </td>
  </tr>
  <tr>
    <th colspan="2">
<form id="idpLoginFrm" name="idpLoginFrm" method="post" action="../sso/sso_idp_login.jsp">
  <input  value="통합 로그인 요청" type="submit" />
  <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= addContextPath(request, "/exsignon/sample/main.jsp") %>" />
</form>
    </th>
  </tr>
</table>

<hr style="margin:20px;">

<table>
  <colgroup>
    <col class="first">
    <col class="second">
  </colgroup>
  <tr>
    <th colspan="2">개별 로그인 페이지를 이용한 로그인</th>
  </tr>
  <tr>
    <td>설명</td>
    <td>
    <p>&nbsp;각 SP에서 로그인 페이지를 가지고 있으면서 로그인 로직을 인증서버에서 처리하는 경우 사용</p>
    </td> 
  </tr>
  <tr>
    <td>요청 URL</td>
    <td>&nbsp;https://인증서버URL/svc/tk/Login.do</td> 
  </tr>
  <tr>
    <td>파라미터</td>
    <td>
<p>* <span class="font_bold">user_id</span> (파라미터명 협의 가능) (필수) : 사용자 아이디</p>
<hr>
<p>* <span class="font_bold">user_password</span> (파라미터명 협의 가능) (필수) : 사용자 비밀번호</p>
<hr>
<p>* <span class="font_bold">id</span> (필수) : 현재 요청을 전달하는 SP ID</p>
<hr>
<p>* <span class="font_bold">RelayState</span> (옵션) : 모든 SSO 인증 절차를 거친 후 이동 할 URL 지정. RelayState가 없을 경우 SP 시스템의 Context path 요청</p>
    </td> 
  </tr>
  <tr>
    <td>샘플 코드</td>
    <td>
<p>&lt;form id=&quot;spLoginFrm&quot; name=&quot;spLoginFrm&quot; method=&quot;post&quot; action=&quot;<%= this.generateUrl(IDP_URL, LOGIN_URL) %>&quot;&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;hidden&quot; name=&quot;<%= RELAY_STATE_NAME %>&quot; value=&quot;<%= addContextPath(request, "/exsignon/sample/main.jsp") %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;hidden&quot; name=&quot;<%= ID_NAME %>&quot; value=&quot;<%= SP_ID %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;아이디 : &lt;input type=&quot;text&quot; name=&quot;user_id&quot; /&gt;&lt;br/&gt;</p>
<p>&nbsp;&nbsp;비밀번호 : &lt;input type=&quot;password&quot; name=&quot;user_password&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;submit&quot; value=&quot;개별 로그인&quot; /&gt;</p>
<p>&lt;/form&gt;</p>
    </td>
  </tr>
  <tr>
    <th colspan="2">
<form id="spLoginFrm" name="spLoginFrm" method="post" action="<%= this.generateUrl(IDP_URL, LOGIN_URL) %>">
  <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= addContextPath(request, "/exsignon/sample/main.jsp") %>" />
  <input type="hidden" name="<%= ID_NAME %>" value="<%= SP_ID %>" />
  
  <div style="width:50%; border:none; float:left; text-align:right;">
    아이디 : <input type="text" name="user_id" style="margin:5px;"/><br/>
    비밀번호 : <input type="password" name="user_password" style="margin:5px;"/>
  </div>
  <div style="width:5px; border:none; float:left;">&nbsp;</div>
  <div style="width:50%; border:none; float:left; text-align:left;">
    <input type="submit" value="개별 로그인" />
  </div>
</form>
    </th>
  </tr>
</table>

<hr style="margin:20px;">

<table>
  <colgroup>
    <col class="first">
    <col class="second">
  </colgroup>
  <tr>
    <th colspan="2">아이디만을 이용한 SSO 세션 생성</th>
  </tr>
  <tr>
    <td>설명</td>
    <td>
    <p>&nbsp;사용자가 이미 특정 시스템에 로그인 된 상황에서 비밀번호를 제외한 사용자 아이디만을 이용하여 SSO 서버에 세션을 생성해야 할 경우 사용.</p>
    <p>&nbsp;사용자 검증 프로세스를 인증서버에서 가지고 있지 않음.</p>
    </td> 
  </tr>
  <tr>
    <td>요청 URL</td>
    <td>&nbsp;/sso/sso_assert.jsp</td> 
  </tr>
  <tr>
    <td>파라미터</td>
    <td>
<p>* <span class="font_bold">nameId</span> (필수) : 사용자 아이디</p>
<hr>
<p>* <span class="font_bold">targetId</span> (필수) : 인증 완료 후 이동할 SP ID</p>
<hr>
<p>* <span class="font_bold">RelayState</span> (옵션) : 모든 SSO 인증 절차를 거친 후 이동 할 URL 지정. RelayState가 없을 경우 SP 시스템의 Context path 요청</p>
    
    </td> 
  </tr>
  <tr>
    <td>샘플 코드</td>
    <td>
<p>&lt;form id=&quot;assertLoginFrm&quot; name=&quot;assertLoginFrm&quot; method=&quot;post&quot; action=&quot;../sso/sso_assert.jsp&quot;&gt;</p>
<p>&nbsp;&nbsp;아이디 : &lt;input type=&quot;text&quot; name=&quot;<%= NAMEID_NAME %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;hidden&quot; name=&quot;<%= TARGET_ID_NAME %>&quot; value=&quot;<%= SP_ID %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input type=&quot;hidden&quot; name=&quot;<%= RELAY_STATE_NAME %>&quot; value=&quot;<%= addContextPath(request, "/exsignon/sample/main.jsp") %>&quot; /&gt;</p>
<p>&nbsp;&nbsp;&lt;input value=&quot;SSO 세션 생성&quot; type=&quot;submit&quot; /&gt;</p>
&lt;/form&gt;</p>
    </td>
  </tr>
  <tr>
    <td><span style="color:red;">* 주의사항</span></td>
    <td><span style="color:red;">&nbsp;이 기능은 인증서버에서 사용자에 대한 검증을 하지 않으므로 로그인 되지 않은 사용자가 아이디만을 가지고 호출할 수 없도록 로컬 세션에 저장된 <b>"eXSignOn.assert.userid"</b> 값을 서버에 세션을 생성할 사용자 아이디로 사용한다. 즉, 이 기능을 사용하기 위해서는 로그인된 사용자 아이디가 로컬 세션에 해당 값으로 저장되어 있어야 한다.</span></td>
  </tr>
  <tr>
    <th colspan="2">
<form id="assertLoginFrm" name="assertLoginFrm" method="post" action="../sample/sso_pre_assert.jsp">
  아이디 : <input type="text" name="<%= NAMEID_NAME %>" />
  <input type="hidden" name="<%= TARGET_ID_NAME %>" value="<%= SP_ID %>" />
  <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= addContextPath(request, "/exsignon/sample/main.jsp") %>" />
  <input value="SSO 세션 생성" type="submit" />
</form>
    </th>
  </tr>
</table>
<%
} else {
%>


<table>
  <colgroup>
    <col class="first">
    <col class="second">
  </colgroup>
  <tr>
    <th colspan="2">로그아웃 요청</th>
  </tr>
  <tr>
    <td>설명</td>
    <td>
    <p>&nbsp;SP 시스템 로그아웃 이후 SSO 통합로그아웃 요청</p>
    <p>&nbsp;logout.jsp 파일을 요청하게 되며 logout.jsp에서는 session invalidate 후 SSO 통합 로그아웃을 요청한다.</p>
    </td> 
  </tr>
  <tr>
    <td>요청 URL</td>
    <td>&nbsp;/sso/logout.jsp</td> 
  </tr>
  <tr>
    <td>파라미터</td>
    <td>
<p>* <span class="font_bold">RelayState</span> (옵션) : 모든 SSO 로그아웃 절차를 거친 후 이동 할 URL 지정. RelayState가 없을 경우 SP 시스템의 Context path 요청</p>
    </td> 
  </tr>
  <tr>
    <th colspan="2">
<form id="logoutFrm" name="logoutFrm" method="post" action="../sso/logout.jsp">
    <input type="submit" value="로그아웃"  />
    <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= addContextPath(request, "/exsignon/sample/main.jsp") %>" />
</form>
    </th>
  </tr>
</table>
<%
}
%>

</body>
</html>