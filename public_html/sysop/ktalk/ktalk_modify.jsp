<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(136, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//제한
if(!isSend) { m.jsError("SMS 서비스를 신청하셔야 이용할 수 있습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
KtalkUserDao ktalkUser = new KtalkUserDao();
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao();
UserDao user = new UserDao();

//정보
DataSet info = ktalk.find("id = " + id + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//정보
DataSet ktinfo = ktalkTemplate.find("template_cd = '" + info.s("template_cd") + "' AND ktalk_cd = '" + info.s("ktalk_cd") + "' AND site_id = " + siteId + " AND status != -1");
if(!ktinfo.next()) { m.jsAlert("해당 템플릿 정보가 없습니다."); return; }


//폼체크
f.addElement("template_id", ktinfo.s("id"), "hname:'템플릿', required:'Y'");
f.addElement("sender", info.s("sender"), "hname:'발신번호', required:'Y'");
//f.addElement("sender_key", SiteConfig.s("ktalk_sender_key"), "hname:'알림톡발송키', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");

//등록
if(m.isPost() && f.validate()) {

	//변수
	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;

	//정보
	DataSet tinfo = ktalkTemplate.find("id = " + f.getInt("template_id") + " AND site_id = " + siteId + " AND status != -1");
	if(!tinfo.next()) { m.jsAlert("해당 템플릿 정보가 없습니다."); return; }

	int newId = ktalk.getSequence();
	ktalk.item("id", newId);
	ktalk.item("site_id", siteId);
	ktalk.item("module", "user");
	ktalk.item("module_id", 0);
	ktalk.item("template_cd", tinfo.s("template_cd"));
	ktalk.item("ktalk_cd", tinfo.s("ktalk_cd"));
	ktalk.item("sender_key", SiteConfig.s("ktalk_sender_key"));
	ktalk.item("user_id", userId);
	ktalk.item("sender", f.get("sender"));

	ktalk.item("subject", tinfo.s("template_nm"));
	ktalk.item("content", f.get("content"));
	ktalk.item("resend_id", id);
	ktalk.item("send_cnt", 0);
	ktalk.item("fail_cnt", 0);
	ktalk.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	ktalk.item("reg_date", m.time("yyyyMMddHHmmss"));
	ktalk.item("status", 1);
	if(!ktalk.insert()) {
		m.js("parent.document.getElementById('prog').style.display = 'none';");
		m.jsAlert("등록하는 중 오류가 발생했습니다."); return;
	}

	String[] tmpArr = f.get("user_idx").split(",");
	DataSet users = user.find("id IN ('" + m.join("','", tmpArr) + "')", "*", "id ASC");

	//SMS 발송
	int sendCnt = 0;
	int failCnt = 0;
	while(users.next()) {
		String mobile = "";
		mobile = !"".equals(users.s("mobile")) ? SimpleAES.decrypt(users.s("mobile")) : "";
		ktalkUser.item("ktalk_id", newId);
		ktalkUser.item("site_id", siteId);
		ktalkUser.item("mobile", users.s("mobile"));
		ktalkUser.item("user_id", users.s("id"));
		ktalkUser.item("user_nm", users.s("user_nm"));
		if(ktalk.isMobile(mobile)) {
			ktalkUser.item("send_yn", "Y");
			if(ktalkUser.insert()) {
				mobile = m.replace(mobile, "-", "");
				//카카오톡발송
				p.clear();
				//p.setVar("SITE_INFO", siteinfo);
				p.setVar(users);
				String content = ktalkTemplate.fetchTemplate(siteId, tinfo.s("template_cd"), p);
				String r = ktalk.send(mobile, f.get("sender"), content, tinfo.s("ktalk_cd"));
				Json _r = new Json(r);
				if("1000".equals(_r.getString("//code"))) sendCnt++;
			}
		} else {
			ktalkUser.item("send_yn", "N");
			if(ktalkUser.insert()) { failCnt++; }
		}
	}

	//발송건수
	ktalk.execute("UPDATE " + ktalk.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId + "");

	m.jsReplace("ktalk_list.jsp?" + m.qs("id"), "parent");
	return;
}


//목록-발송회원
DataSet users = ktalkUser.query(
	"SELECT a.user_id, u.user_nm, u.mobile, u.login_id, u.sms_yn "
	+ " FROM " + ktalkUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.ktalk_id = " + id + " AND a.site_id = " + siteId + ""
);
while(users.next()) {
	users.put("s_value", !"".equals(users.s("mobile")) ? SimpleAES.decrypt(users.s("mobile")) : "-" );
	users.put("sms_yn_conv", m.getItem(users.s("sms_yn"), user.receiveYn));
}

//기록-개인정보조회
_log.add("V", Menu.menuNm, users.size(), "이러닝 운영", users);

//출력
p.setBody("ktalk.ktalk_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("t_link", "modify");

p.setLoop("hours", ktalk.getHours());
p.setLoop("minutes", ktalk.getMinutes());
//p.setLoop("status_list", m.arr2loop(cu.statusList));

p.setLoop("users", users);
p.setLoop("templates", ktalkTemplate.find("site_id = " + siteId + " AND status = 1"));
p.display();

%>