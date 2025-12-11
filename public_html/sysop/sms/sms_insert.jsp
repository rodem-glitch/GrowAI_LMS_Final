<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(40, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//제한
if(!isSend) { m.jsError("SMS 서비스를 신청하셔야 이용할 수 있습니다."); return; }

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();

//정보-회원
DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + "");
if(!uinfo.next()) { m.jsError("해당 회원정보가 없습니다."); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "";

//폼체크
f.addElement("sms_type", "A", "hname:'SMS유형', required:'Y'");
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

	int newId = sms.getSequence();

	sms.item("id", newId);
	sms.item("site_id", siteId);

	sms.item("module", "user");
	sms.item("module_id", 0);
	sms.item("user_id", userId);
	sms.item("sms_type", f.get("sms_type", "A"));
	sms.item("sender", f.get("sender"));
	sms.item("content", f.get("content"));
	sms.item("resend_id", 0);
	sms.item("send_cnt", 0);
	sms.item("fail_cnt", 0);
	sms.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	sms.item("reg_date", m.time("yyyyMMddHHmmss"));
	sms.item("status", 1);

	if(!sms.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); m.js("parent.CloseLayer();"); return; }

	String[] tmpArr = m.rs("user_idx").split(",");
	DataSet users = user.find("id IN ('" + m.join("','", tmpArr) + "')", "*", "id ASC");

	//SMS 발송
	boolean isAd = "A".equals(f.get("sms_type", "A"));
	int sendCnt = 0;
	int failCnt = 0;
	while(users.next()) {
		mobile = "";
		mobile = !"".equals(users.s("mobile")) ? SimpleAES.decrypt(users.s("mobile")) : "";
		smsUser.item("site_id", siteId);
		smsUser.item("sms_id", newId);
		smsUser.item("mobile", users.s("mobile"));
		smsUser.item("user_id", users.s("id"));
		smsUser.item("user_nm", users.s("user_nm"));
		if(sms.isMobile(mobile) && (!isAd || (isAd && users.b("sms_yn")))) {
			smsUser.item("send_yn", "Y");
			if(smsUser.insert()) {
				if(isSend) sms.send(mobile, f.get("sender"), (isAd ? "(광고) " : "") + f.get("content"), sendDate);
				sendCnt++;
			}
		} else {
			smsUser.item("send_yn", "N");
			if(smsUser.insert()) { failCnt++; }
		}
	}

	//발송건수
	sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId);

	m.jsReplace("sms_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("sms.sms_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.setLoop("types", m.arr2loop(sms.types));

p.setVar("t_link", "insert");
p.setVar("sms_type", "A");
p.display();

%>