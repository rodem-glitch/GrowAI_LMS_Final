<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
if(!isSend) { m.jsAlert("SMS 서비스를 신청하셔야 이용할 수 있습니다."); m.js("parent.CloseLayer();"); return; }

//폼입력
String idx = m.rs("idx");

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();

//정보-회원
DataSet uinfo = user.find("id = " + userId + "");
if(!uinfo.next()) { m.jsAlert("해당 회원 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }
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

	//제한-글작성수
	if(2 < sms.findCount("site_id = " + siteId + " AND user_id = " + userId + " AND reg_date >= '" + m.addDate("I", -1, sysNow, "yyyyMMddHHmmss") + "' AND status != -1")) {
		m.jsAlert("단기간에 많은 문자를 발송해 등록이 차단되었습니다.\\n잠시 후 다시 시도해주세요.");
		return;
	}

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

	m.jsAlert("발송되었습니다.");
	m.js("parent.CloseLayer();");
	return;
}

//목록-발송회원
DataSet users = user.query(
	"SELECT a.*"
	+ " FROM " + user.table + " a"
	+ " WHERE a.id IN (" + idx + ") AND (a.mobile IS NOT NULL OR a.mobile != '')"
);
while(users.next()) {
	users.put("s_value", !"".equals(users.s("mobile")) ? "(" + SimpleAES.decrypt(users.s("mobile")) + ")" : "(-)" );
	//users.put("stype_yn", !"Y".equals(users.s("email_yn")) ? "[수신거부]" : "");
}

//기록-개인정보조회
_log.add("V", "SMS발송", users.size(), "이러닝 운영", users);

//출력
p.setLayout("poplayer");
p.setBody("sms.pop_sms");
p.setVar("p_title", "SMS발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("users", users);

p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.setLoop("types", m.arr2loop(sms.types));

p.setVar("sms_type", "A");
p.display();

%>