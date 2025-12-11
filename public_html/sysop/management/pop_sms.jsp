<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//기본키
String[] idx = f.getArr("idx");
//if("".equals(idx)) { m.jsErrClose("기본키는 반드시 입력해야 합니다."); return; }

//객체
SmsDao sms = new SmsDao(siteId);
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao(isBlindUser);
CourseUserDao courseUser = new CourseUserDao();

boolean isSend = siteinfo.b("sms_yn");
if(isSend) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//제한
if(!isSend) { m.jsError("SMS 서비스를 신청하셔야 이용할 수 있습니다."); return; }

f.addElement("sender", siteinfo.s("sms_sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", "[" + cinfo.s("course_nm") + "]", "hname:'내용', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");

//등록
if("insert".equals(f.get("p_type")) && m.isPost() && f.validate()) {

	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;

	int newId = sms.getSequence();

	sms.item("id", newId);
	sms.item("site_id", siteId);

	sms.item("module", "course");
	sms.item("module_id", courseId);
	sms.item("user_id", userId);
	sms.item("sender", f.get("sender"));
	sms.item("content", f.get("content"));
	sms.item("send_cnt", 0);
	sms.item("fail_cnt", 0);
	sms.item("resend_id", 0);
	sms.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	sms.item("reg_date", m.time("yyyyMMddHHmmss"));
	sms.item("status", 1);

	if(!sms.insert()) { m.jsError("등록하는 중 오류가 발생 했습니다."); return; }

	String[] tmpArr = m.request("user_idx").split(",");
	DataSet userList = user.find("status > -1 AND id IN (" + m.join(",", tmpArr) + ")", "*", "id ASC");

	//Sms발송
	int sendCnt = 0;
	int failCnt = 0;
	while(userList.next()) {
		smsUser.item("site_id", siteId);
		smsUser.item("sms_id", newId);
		smsUser.item("mobile", userList.s("mobile"));
		smsUser.item("user_id", userList.s("id"));
		smsUser.item("user_nm", userList.s("user_nm"));

		String mobile = !"".equals(userList.s("mobile")) ? SimpleAES.decrypt(userList.s("mobile")) : "";

		if(sms.isMobile(mobile)) {
			smsUser.item("send_yn", "Y");
			if(smsUser.insert()) {
				sms.send(mobile, f.get("sender"), f.get("content"), sendDate);
				sendCnt++;
			}
		} else {
			smsUser.item("send_yn", "N");
			if(smsUser.insert()) {
				failCnt++;
			}
		}
	}

	//발송건수
	sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId + "");
	m.jsErrClose("발송되었습니다.", "parent");
	return;
}

//발송회원
DataSet users = new DataSet();
if(idx != null) {
	users = courseUser.query(
		"SELECT a.id, a.user_nm, a.login_id, a.mobile "
		+ " FROM " + user.table + " a "
		+ " WHERE a.id IN (" + (m.join(",", idx)) + ") "
		+ " AND (a.mobile IS NOT NULL AND a.mobile != '') "
		+ " AND EXISTS ( "
			+ " SELECT 1 FROM " + courseUser.table + " "
			+ " WHERE user_id = a.id AND course_id = " + courseId + " AND status IN (1, 3) "
		+ " )"
	);
}
while(users.next()) {
	String mobile = "";
	mobile = !"".equals(users.s("mobile")) ? SimpleAES.decrypt(users.s("mobile")) : "";
	users.put("mobile", mobile);
	users.put("s_value", "( " + mobile + " )");
	//users.put("stype_yn", !"Y".equals(users.getString("sms")) ? "[수신거부]" : "");
}

//기록-개인정보조회
if(users.size() > 0 && !isBlindUser) _log.add("V", "쪽지발송", users.size(), "이러닝 운영", users);

//출력
p.setLayout("pop");
p.setBody("management.pop_sms");
p.setVar("p_title", "SMS발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.setLoop("users", users);

p.display();

%>