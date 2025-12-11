<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
if(!isSend) { m.jsAlert("SMS 서비스를 신청하셔야 이용할 수 있습니다."); m.js("parent.CloseLayer();");return; }

//기본키
String cmid = m.rs("cmid");
if("".equals(cmid)) {
	m.jsErrClose("기본키는 반드시 지정해야 합니다.");
	return;
}

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();
BizSMS bizSMS = new BizSMS();

//정보-회원
DataSet uinfo = user.find("id = " + userId + "");
if(!uinfo.next()) { m.jsAlert("해당 회원 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "";

//정보-SMS
DataSet binfo = bizSMS.find("cmid = " + cmid + " AND (dest_phone IS NOT NULL OR dest_phone != '')");
if(!binfo.next()) { m.jsAlert("해당 발신정보가 없습니다."); m.js("parent.CloseLayer();"); return; }

//폼체크
f.addElement("sender", siteinfo.s("sms_sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", null, "hname:'내용', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");

//등록
if(m.isPost() && f.validate()) {

	//변수
	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;

	//SMS 발송
	binfo.first();
	while(binfo.next()) {
		if(sms.isMobile(mobile)) sms.send(binfo.s("dest_phone"), f.get("sender"), f.get("content"), sendDate, f.get("title"));
	}

	m.jsAlert("발송되었습니다.");
	m.js("parent.CloseLayer();");
	return;
}

//기록-개인정보조회
_log.add("V", "SMS발송", uinfo.size(), "이러닝 운영", uinfo);

//출력
p.setLayout("poplayer");
p.setBody("sms.pop_biz_sms");
p.setVar("p_title", "SMS발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(binfo);

p.setVar("is_send", isSend);
p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.display();

%>