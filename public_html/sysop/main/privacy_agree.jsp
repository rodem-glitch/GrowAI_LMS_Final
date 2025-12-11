<%@ page contentType="text/html; charset=utf-8" %><%@ include file="./init.jsp" %><%

if("Y".equals(SiteConfig.s("allow_masking_yn"))){
    m.jsAlert("관리자에게 문의하세요.");
    m.js("parent.location.href = parent.location.href;");
    return;
}


String ref = m.rs("referer", request.getHeader("referer"));
String md = m.rs("md", "mode");

//폼체크
f.addElement("purpose", m.getCookie("INQUIRYPURPOSE"), "hname:'조회목적', required:'Y'");

//동의
if(m.isPost() && f.validate()) {

    m.setCookie("PCONFIRM_YN", "Y");
    m.setCookie("INQUIRYPURPOSE", f.get("purpose"));

    if("exdown".equals(m.rs("mode"))) {
        m.js("parent.parent.goExcel(null, '" + md + "', '" + f.get("referer", ref) + "');");
        m.js("parent.parent.CloseLayer();");
    } else {
        //이동
        m.js("parent.parent.location.href = parent.parent.location.href;");
    }
    return;
}

//출력
p.setLayout("poplayer");
p.setBody("main.privacy_agree");
p.setVar("p_title", "exdown".equals(m.rs("mode")) ? "개인 정보 보기" : "가려진 정보 보기");
p.setVar("form_script", f.getScript());

p.setVar("referer", ref);

p.display();

%>