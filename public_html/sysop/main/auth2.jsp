<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

// "E=>이메일", "S=>SMS", "O=>OTP"

//객체
Auth2LogDao auth2Log = new Auth2LogDao(siteId, "sysop");
UserDao user = new UserDao();
MailDao mail = new MailDao();
MailTemplateDao mailTemplate = new MailTemplateDao();
SmsDao sms = new SmsDao(siteId);
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//변수
String returl = m.rs("returl", "/sysop/index.jsp");
String mode = m.rs("mode");
String now = m.time("yyyyMMddHHmmss");
String authNo = "";
int gapLimit = 5 * 60; //제한-gapLimit초
int gapSeconds = 0;

String auth2Type = m.rs("auth2_type", siteinfo.s("auth2_type"));

String msg = "";

//폼체크
f.addElement("auth_no", null, "hname:'인증번호', required:'Y'");

//정보
DataSet uinfo = user.find("user_nm = '" + userName + "' AND login_Id = '" + loginId + "' AND status = 1 AND site_id = " + siteId + " ");
if(!uinfo.next()) { m.jsAlert("정확하지 않은 회원정보입니다.");	return; } // member.error.imprecise
if("O".equals(auth2Type) && "".equals(uinfo.s("otp_key"))) {
    m.js(""
            + "if(!confirm(\"OTP 인증을 위한 키가 등록되어있지 않습니다.\\n인증키 등록페이지로 이동하시겠습니까?\")){ "
            + "    parent.location.href = 'auth2.jsp?auth2_type=E&returl=" + returl + "'"
            + "} else { "
            + "    parent.location.href = 'otpkey_register.jsp?" + m.qs() + "'; "
            + " } "
    );
    return;
}

if(("E".equals(auth2Type) || "S".equals(auth2Type)) && "send".equals(mode)) {

    gapSeconds = !"".equals(m.getSession(auth2Type + "_SENDDATE_OTP")) ? m.diffDate("S", m.getSession(auth2Type + "_SENDDATE_OTP"), now) : 999;
    if (gapSeconds < gapLimit) {

        msg = auth2Log.getTimeString(gapSeconds) + " 전에 인증번호가 발송되었습니다.<br/>잠시 후에 인증번호를 발급 받으시기 바랍니다.";

        auth2Log.setCurrTime(gapLimit - gapSeconds);
        auth2Log.writeMessage(msg, "-1", out);
        return; // member.auth.error.limit
    }

    //email
    if("E".equals(auth2Type)) {
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
            m.setSession(auth2Type + "_SENDDATE_OTP", now);

            msg = "등록된 이메일로 인증번호가 발급되었습니다. <br />이메일을 확인하시기 바랍니다.";
            auth2Log.writeMessage(msg, "1", out);
            return;
        } else {
            msg = "이메일 형식이 맞지 않거나 이메일이 등록되어 있지 않습니다. <br />2차인증을 진행할 수 없습니다. <br />(관리자에게 문의하세요)";
            auth2Log.writeMessage(msg, "-1", out);
            return;
        }
    } else if("S".equals(auth2Type)) {

        if(!siteinfo.b("sms_yn")) {
            msg = "SMS서비스를 지원하지 않습니다. <br />(관리자에게 문의하세요)";
            auth2Log.writeMessage(msg, "-1", out);
            return;
        }

        String mobile = uinfo.s("mobile");

        //SMS
        if(sms.isMobile(mobile)) {

            //변수
            authNo = "" + m.getRandInt(123456, 864198);

            p.setVar("auth_no", authNo);
            smsTemplate.sendSms(siteinfo, uinfo, "findpw_authno", p);

            //세션
            m.setSession("SITE_ID", siteId);
            m.setSession("LOGIN_ID", loginId);
            m.setSession("MOBILE", mobile);
            m.setSession("USER_NM", userName);
            m.setSession("AUTH_NO_OTP", authNo);
            m.setSession(auth2Type + "_SENDDATE_OTP", now);

            msg = "등록된 휴대전화로 인증번호가 발급되었습니다.<br />휴대전화를 확인하시기 바랍니다.";
            auth2Log.writeMessage(msg, "1", out);
            return;
        } else {
            msg = "유효하지 않은 휴대전화번호입니다.<br />(관리자에게 문의하세요)";
            auth2Log.writeMessage(msg, "-1", out);
            return;
        }
    }
} else if("send".equals(mode)) {
    msg = "사용 가능한 2차인증 수단이 없습니다.";
    auth2Log.writeMessage(msg, "-1", out);
    return;
}

//인증
if(m.isPost() && f.validate()) {
    authNo = f.get("auth_no");

    String sessAuthNo = m.getSession("AUTH_NO_OTP");
    String sessSendDate = m.getSession(auth2Type + "_SENDDATE_OTP");

    //EMAIL, SMS
    if("E".equals(auth2Type) || "S".equals(auth2Type)) {
        auth2Log.setInfo(auth2Type, authNo, sessAuthNo, sessSendDate, "N");

        if(!(""+siteId).equals(m.getSession("SITE_ID"))
                || (!loginId.equals(m.getSession("LOGIN_ID")))
                || !userName.equals(m.getSession("USER_NM"))
        ) {
            m.jsAlert("잘못된 접근입니다.");
            m.log("auth2", "잘못된 접근입니다 : siteId = " + m.getSession("SITE_ID") + ", loginId = " + m.getSession("LOGIN_ID") + ", user_nm = " + m.getSession("USER_NM"));
            return;
        }

        gapSeconds = !"".equals(sessSendDate) ? m.diffDate("S", sessSendDate, now) : 999;
        if(gapSeconds > gapLimit) {
            if(0 == auth2Log.add(userId)) { }

            m.jsAlert("인증번호의 유효시간이 지났습니다.\n인증번호를 다시 발급받으시기 바랍니다.");
            return;
        }

        //인증번호확인
        if(!authNo.equals(sessAuthNo)) {
            if(0 == auth2Log.add(userId)) { }

            int failCnt = uinfo.i("fail_cnt");
            user.item("fail_cnt", ++failCnt);
            if(!user.update("id = " + uinfo.i("id") + " AND site_id = " + siteId)) { }
            m.log("admin_auth_login", "인증번호 불일치 --> site_id = " + siteId + " / user_id = " + uinfo.i("id") + " / login_id = " + uinfo.s("login_id") + " / fail_cnt = " + failCnt);

            m.jsAlert("인증번호가 일치하지 않습니다.");
            return;
        }

        m.setSession("AUTH_NO_OTP", "");
        m.setSession(auth2Type + "_SENDDATE_OTP", "");

    } else if("O".equals(auth2Type)) { //OTP
        if(!auth2Log.verifyAuthNo(m.parseInt(authNo), uinfo.s("otp_key"))) {
            auth2Log.setInfo(auth2Type, authNo, "" + auth2Log.getHash(uinfo.s("otp_key"), m.parseInt(authNo)), "", "N");
            if(0 == auth2Log.add(userId)) { }

            m.jsAlert("인증번호가 일치하지 않습니다.");
            return;
        } else {
            sessAuthNo = "" + auth2Log.getHash(uinfo.s("otp_key"), m.parseInt(authNo));
        }
    }

    //세션
    auth.put("AUTH2_YN", "Y");
    auth.setAuthInfo();

    auth2Log.setInfo(auth2Type, authNo, sessAuthNo, sessSendDate, "Y");
    if(0 == auth2Log.add(userId)) { }

    //이동
    m.jsReplace(returl, "parent");
    return;
}

//출력
p.setLayout("blank");
p.setBody("main.auth2");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("returl", returl);
p.setVar("domain", request.getServerName());
p.setVar("auth2_type", auth2Type);
p.setVar("auth2_multitype_block", "Y".equals(SiteConfig.s("auth2_multitype_yn")));
p.setVar("curr_time", Math.max(gapSeconds, gapLimit));
p.setVar("otp_block", !"".equals(m.getSession("OTP_KEY")) && !"".equals(m.getSession("BARCODE_URL")));

p.display();

%>