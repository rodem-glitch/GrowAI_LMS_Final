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
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();

//정보
DataSet info = sms.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("sms_type_conv", m.getItem(info.s("sms_type"), sms.types));

//정보-회원
DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
if(!uinfo.next()) { m.jsError("해당 회원정보가 없습니다."); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "";

//폼체크
f.addElement("group_id", info.s("module_id"), "hname:'회원그룹', required:'Y'");
f.addElement("sender", info.s("sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", info.s("content"), "hname:'내용', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");

//등록
if(m.isPost() && f.validate()) {

	//정보
	DataSet ginfo = group.find("id = '" + f.getInt("group_id") + "' AND site_id = " + siteId + "");
	if(!ginfo.next()) { m.jsAlert("해당 그룹 정보가 없습니다."); return; }
	String depts = !"".equals(ginfo.s("depts")) ? m.replace(ginfo.s("depts").substring(1, ginfo.s("depts").length()-1), "|", ",") : "";

	//변수
	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;
	int newId = sms.getSequence();

	sms.item("id", newId);
	sms.item("site_id", siteId);

	sms.item("module", "group");
	sms.item("module_id", f.get("group_id"));
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

	DataSet users = user.query(
		"SELECT a.* "
		+ " FROM " + user.table + " a "
		+ " WHERE a.site_id = " + siteId + " AND (a.mobile IS NOT NULL OR a.mobile != '') "
		+ (!"".equals(depts)
				? " AND a.status = 1 AND ( a.dept_id IN (" + depts + ") OR "
				: " AND ( a.status = 1 AND ")
		+ " EXISTS ( "
			+ " SELECT 1 FROM " + groupUser.table + " "
			+ " WHERE group_id = " + f.get("group_id") + " AND add_type = 'A' "
			+ " AND user_id = a.id "
		+ " ) ) AND NOT EXISTS ( "
			+ " SELECT 1 FROM " + groupUser.table + " "
			+ " WHERE group_id = " + f.get("group_id") + " AND add_type = 'D' "
			+ " AND user_id = a.id "
		+ " ) "
	);

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
	sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId + "");

	m.jsReplace("sms_list.jsp?" + m.qs("id"), "parent");
	return;
}

//목록
DataSet groups = group.find("status = 1 AND site_id = " + siteId + "", "*", "group_nm ASC");

//출력
p.setBody("sms.sms_group_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("t_link", "modify");

p.setLoop("groups", groups);
p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.display();

%>