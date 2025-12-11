<%@ page import="org.json.JSONObject"%><%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
Auth2LogDao auth2Log = new Auth2LogDao(siteId, "sysop");
UserDao user = new UserDao();
MailDao mail = new MailDao();
MailTemplateDao mailTemplate = new MailTemplateDao();

//변수
String returl = m.rs("returl", "/sysop/index.jsp");
String mode = m.rs("mode");
String now = m.time("yyyyMMddHHmmss");
String authNo = "";
int gapLimit = 5 * 60; //제한-gapLimit초
int gapSeconds = 0;

//String auth2Type = siteinfo.s("auth2_type");
String auth2Type = m.rs("auth2_type", siteinfo.s("auth2_type"));

String msg = "";

//정보
DataSet uinfo = user.find("user_nm = '" + userName + "' AND login_Id = '" + loginId + "' AND status = 1 AND site_id = " + siteId + " ");
if(!uinfo.next()) { m.jsAlert("정확하지 않은 회원정보입니다.");	return; } // member.error.imprecise

if("send".equals(mode) && (!"".equals(m.getSession("OTP_KEY")) && !"".equals(m.getSession("BARCODE_URL")))){
    JSONObject key = new JSONObject();
    key.put("encoded_key", m.getSession("OTP_KEY"));
    key.put("barcode_url", m.getSession("BARCODE_URL"));
    auth2Log.writeMessage(key.toString(), "2", out);
    return;
} else if(("O".equals(auth2Type) && "".equals(uinfo.s("otp_key"))) && "send".equals(mode) && "".equals(m.getSession("OTP_KEY"))) {

    gapSeconds = !"".equals(m.getSession("EO_SENDDATE_OTP")) ? m.diffDate("S", m.getSession("EO_SENDDATE_OTP"), now) : 999;
    if (gapSeconds < gapLimit) {
        msg = auth2Log.getTimeString(gapSeconds) + " 전에 인증번호가 발송되었습니다.<br/>잠시 후에 인증번호를 발급 받으시기 바랍니다.";

        auth2Log.setCurrTime(gapLimit - gapSeconds);
        auth2Log.writeMessage(msg, "-1", out);
        return; // member.auth.error.limit
    }

    //메일
    if (mail.isMail(uinfo.s("email"))) {

        //발송
        authNo = "" + m.getRandInt(123456, 864198);
        p.setVar("auth_no", authNo);
        mailTemplate.sendMail(siteinfo, uinfo, "findpw_authno", "인증번호가 발급되었습니다.", p);
        //세션
        m.setSession("SITE_ID", siteId);
        m.setSession("LOGIN_ID", loginId);
        m.setSession("EMAIL", uinfo.s("email"));
        m.setSession("USER_NM", userName);
        m.setSession("AUTH_NO_OTP", authNo);
        m.setSession("EO_SENDDATE_OTP", now);

        msg = "OTP키 등록을 위해<br />등록된 이메일로 인증번호가 발급되었습니다. <br />이메일을 확인하시기 바랍니다.";
        auth2Log.writeMessage(msg, "1", out);
        return;
    } else {
        msg = "이메일 형식이 맞지 않거나 이메일이 등록되어 있지 않습니다. <br />2차인증을 진행할 수 없습니다. <br />(관리자에게 문의하세요)";
        auth2Log.writeMessage(msg, "-1", out);
        return;
    }
} else if(!"".equals(uinfo.s("otp_key")) && "send".equals(mode)){
    msg = "이미 OTP가 등록된 계정입니다. <br />(관리자에게 문의하세요)";
    auth2Log.writeMessage(msg, "-1", out);
    return;
}

if("verify".equals(mode) && !"".equals(m.rs("auth_no"))) {
    authNo = m.rs("auth_no");

    if(!(""+siteId).equals(m.getSession("SITE_ID"))
            || (!loginId.equals(m.getSession("LOGIN_ID")))
            || !userName.equals(m.getSession("USER_NM"))
            || !"O".equals(auth2Type)
    ) {
        m.log("otpkey-register", "잘못된 접근입니다 : siteId = " + m.getSession("SITE_ID") + ", loginId = " + m.getSession("LOGIN_ID") + ", userNm = " + m.getSession("USER_NM") + ", auth2Type = " + auth2Type);
        auth2Log.writeMessage("잘못된 접근입니다.", "-99", out);
        return;
    }

    //EMAIL
    gapSeconds = !"".equals(m.getSession("EO_SENDDATE_OTP")) ? m.diffDate("S", m.getSession("EO_SENDDATE_OTP"), now) : 999;
    if(gapSeconds > gapLimit) {
        auth2Log.writeMessage("인증번호의 유효시간이 지났습니다.<br/>인증번호를 다시 발급받으시기 바랍니다.", "-1", out);
        return;
    }

    //인증번호확인
    if(!authNo.equals(m.getSession("AUTH_NO_OTP"))) {
        auth2Log.writeMessage("인증번호가 일치하지 않습니다.", "-1", out);
        return;
    }

    m.setSession("AUTH_NO_OTP", "");
    m.setSession("EO_SENDDATE_OTP", "");

    JSONObject key = auth2Log.generateBarcode(loginId, siteinfo.s("site_nm"));

    m.setSession("OTP_KEY", key.getString("encoded_key"));
    m.setSession("BARCODE_URL", key.getString("barcode_url"));
    auth2Log.writeMessage(key.toString(), "1", out);

    return;
}

if(m.isPost() && f.validate()) {

    if(!(""+siteId).equals(m.getSession("SITE_ID"))
            || (!loginId.equals(m.getSession("LOGIN_ID")))
            || !userName.equals(m.getSession("USER_NM"))
            || !"O".equals(auth2Type)
            || "".equals(m.getSession("OTP_KEY"))
            || "".equals(m.getSession("BARCODE_URL"))
    ) {
        m.log("otpkey-register", "잘못된 접근입니다 : siteId = " + m.getSession("SITE_ID") + ", loginId = " + m.getSession("LOGIN_ID") + ", userNm = " + m.getSession("USER_NM") + ", auth2Type = " + auth2Type);
        m.jsAlert("잘못된 접근입니다."); return;
    }

    user.clear();
    user.item("otp_key", m.getSession("OTP_KEY"));
    if(!user.update("id = " + userId + "")) {
        m.jsAlert("수정하는 중 오류가 발생했습니다.");
        return;
    }

    m.jsAlert("정상적으로 OTP를 등록하였습니다.");

    //이동
    m.jsReplace("auth2.jsp?" + m.qs(), "parent");
    return;
}

//출력
p.setLayout("blank");
p.setBody("main.otpkey_register");
p.setVar("form_script", f.getScript());

p.setVar("returl", returl);
p.setVar("domain", request.getServerName());
p.setVar("auth2_type", auth2Type);
p.setVar("curr_time", Math.max(gapSeconds, gapLimit));

p.display();

%>