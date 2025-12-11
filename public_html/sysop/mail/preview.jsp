<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//변수
String mailTemplate = f.get("mbody");

f.addElement("mbody", mailTemplate, "hname:'내용', allowhtml:'Y'");

if(!"body".equals(m.rs("mode"))) {
	boolean isAd = "A".equals(f.get("mail_type", "A"));
	String today = m.time("yyyy년 MM월 dd일");
	String agreeInfo = _message.get("mail.agree_info", new String[] { "agree_date_conv=>" + today, "domain=>" + siteinfo.s("domain"), "ek=>", "key=>" });

	//템플릿
	p.setRoot(siteinfo.s("doc_root") + "/html");
	p.setVar("SITE_INFO", siteinfo);
	p.setVar("subject", f.get("subject", "메일제목이 들어가는 부분입니다."));
	p.setVar("MBODY", f.get("mbody"));
	if(isAd) p.setVar("agree_info", agreeInfo);
	mailTemplate = p.fetchRoot("mail/template.html");
}

%>
<!DOCTYPE html>
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title><%=winTitle%></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<script language="javascript" type="text/javascript" src="/common/js/jquery-1.12.3.min.js" charset="utf-8"></script>
</html>
<body>

<%
out.print(mailTemplate);
%>

<script>
$(document).ready(function() {
	$(".ad_data a").removeAttr("href");
});
</script>
</body>
</html>