<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String mode = m.rs("mode");
String returl = !"".equals(m.rs("returl")) ? m.rs("returl") : "/sysop/main/login.jsp";

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
    m.jsReplace(returl);
    return;
}

UserDao user = new UserDao();

DataSet uinfo = user.find("id = " + userId + " AND status = 1");
if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; } //회원 정보가 없습니다.

//폼체크
f.addElement("passwd_old", null, "hname:'기존 비밀번호', required:'Y'");
f.addElement("passwd", null, "hname:'신규 비밀번호', required:'Y'");
f.addElement("passwd2", null, "hname:'비밀번호 확인', match:'passwd', required:'Y'");

//처리-연기
if("DELAY".equals(m.rs("mode"))) {
    user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));
    if(!user.update("id = " + userId)) {
        m.jsAlert(_message.get("alert.common.error_modify"));//수정하는 중 오류가 발생했습니다.
        return;
    }
    m.jsReplace("/sysop/main/modify_passwd.jsp?" + m.qs("mode"), "parent");
    return;
}

//수정
if(m.isPost() && f.validate()) {

    //변수
    String passwdOld = f.get("passwd_old");
    String passwd = f.get("passwd");

    //제한-비밀번호
    if(!passwd.matches("^(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[\\W_]).{9,}$")) {
        m.jsAlert(_message.get("alert.member.rule_password")); //비밀번호는 영문, 숫자, 특수문자 조합 9자 이상 입력하세요.
        m.jsReplace("/sysop/main/modify_passwd.jsp?" + m.qs(), "parent");
        return;
    }

    if(64 > passwd.length()) passwd = m.encrypt(passwd, "SHA-256");
    if(64 > passwdOld.length()) passwdOld = m.encrypt(passwdOld, "SHA-256");

    //제한
    if(!passwdOld.equals(uinfo.s("passwd"))) {
        m.jsAlert(_message.get("alert.member.reenter_password")); //비밀번호 확인하세요.

//        m.js("parent.resetAllPassword();");
        m.jsReplace("/sysop/main/modify_passwd.jsp?" + m.qs(), "parent");
        return;
    }

    user.item("passwd", passwd);
    user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));

    if(!user.update("id = " + userId)) {
        m.jsAlert(_message.get("alert.common.error_modify")); //수정하는 중 오류가 발생했습니다.
        m.js("parent.resetAllPassword();");
        m.jsReplace("/sysop/main/modify_passwd.jsp?" + m.qs(), "parent");
        return;
    }

    m.jsAlert("비밀번호가 변경되었습니다. 다시 로그인 하시기 바랍니다.");
    m.jsReplace("/sysop/main/logout.jsp", "parent");

    //m.jsReplace(returl, "parent");
    return;
} else {
    auth.put("MODIFY_PASSWD", "N");
    auth.setAuthInfo();
}

//출력
p.setLayout("blank");
p.setBody("main.modify_passwd");
p.setVar("p_title", "비밀번호변경");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());

p.setVar("expired_block", "expired".equals(mode));
p.display();

%>