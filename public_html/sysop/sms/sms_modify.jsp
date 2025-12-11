<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(40, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//제한
if(!isSend) { m.jsError("SMS 서비스를 신청하셔야 이용할 수 있습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();

//정보
DataSet info = sms.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("sms_type_conv", m.getItem(info.s("sms_type"), sms.types));
info.put("send_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("send_date")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));

//정보-회원
DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + "");
if(!uinfo.next()) { m.jsError("해당 회원정보가 없습니다."); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "";

//폼체크
f.addElement("sender", info.s("sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", info.s("content"), "hname:'내용', required:'Y'");
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
	sms.item("sms_type", info.s("sms_type"));
	sms.item("sender", f.get("sender"));
	sms.item("content", f.get("content"));
	sms.item("resend_id", id);
	sms.item("send_cnt", 0);
	sms.item("fail_cnt", 0);
	sms.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	sms.item("reg_date", m.time("yyyyMMddHHmmss"));
	sms.item("status", 1);

	if(!sms.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	String[] tmpArr = m.rs("user_idx").split(",");
	DataSet users = user.find("id IN ('" + m.join("','", tmpArr) + "')", "*", "id ASC");

	//SMS 발송
	boolean isAd = "A".equals(info.s("sms_type"));
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

//목록-발송회원
DataSet users = smsUser.query(
	"SELECT a.user_id, u.user_nm, u.mobile, u.login_id, u.sms_yn "
	+ " FROM " + smsUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.sms_id = " + id + " "
);
while(users.next()) {
	users.put("s_value", !"".equals(users.s("mobile")) ? SimpleAES.decrypt(users.s("mobile")) : "-" );
	users.put("sms_yn_conv", m.getItem(users.s("sms_yn"), user.receiveYn));
}

//기록-개인정보조회
if(users.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, users.size(), "이러닝 운영", users);

//출력
p.setBody("sms.sms_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("t_link", "modify");

p.setLoop("users", users);
p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.display();

%>