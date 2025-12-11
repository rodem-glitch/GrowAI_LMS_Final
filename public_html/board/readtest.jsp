<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//정보
DataSet info = post.query(
	" SELECT a.*, u.login_id "
	+ " FROM " + post.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = ? AND a.display_yn = 'Y' AND a.status = 1 AND a.site_id = " + siteId + ""
	+ (binfo.b("private_yn") ? " AND a.user_id = " + userId : "")
	+ ("qna".equals(btype) ? " AND a.depth = 'A' " : "")
	, new Object[] { 1065 }
);
if(!info.next()) { m.jsError(_message.get("alert.post.nodata")); return; }
out.println("=====<br>");
out.println("<xmp style=\"font-size: 2em;\">" + info.s("content") + "</xmp><br>");
out.println("=====<br>");





String allowTags = "a,b,br,cite,code,dd,dl,dt,div,em,i,li,ol,p,pre,q,small,span,strike,strong,sub,sup,u,ul,article,aside,details,div,dt,figcaption,footer,form,fieldset,header,hgroup,html,main,nav,section,summary,body,p,dl,multicol,dd,figure,address,center,blockquote,h1,h2,h3,h4,h5,h6,listing,xmp,pre,plaintext,menu,dir,ul,ol,li,hr,table,tbody,thead,tfoot,th,tr,td,caption,textarea,img,input,textarea,hr,iframe,video,audio,object,embed";
String allowRegexr = "<(\\/?)(?!.*" + Malgn.replace(allowTags, ",", "[ >]|.*") + "[ >])([^>]*)>";
info.put("content", info.s("content").replaceAll(allowRegexr, "&lt;$1$2&gt;"));








out.println("=====<br>");
out.println("<xmp style=\"font-size: 2em;\">" + info.s("content") + "</xmp><br>");
out.println("=====<br><details>테스트</details>");


//info.put("content_conv", Malgn.htt(info.s("content")));


%>