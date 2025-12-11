<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(113, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserSleepDao userSleep = new UserSleepDao();

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(user.table + " a ");
lm.setFields("a.*");
lm.addWhere("a.status = 31");
lm.addWhere("a.user_kind = 'U'");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.login_id, a.user_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//변수
String now = m.time("yyyyMMddHHmmss");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("sleep_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("sleep_date")));
	
	if("".equals(list.s("conn_date"))) list.put("conn_date", list.s("reg_date"));
	list.put("conn_diff", m.nf(m.diffDate("D", list.s("conn_date"), now)));
	list.put("sleep_diff", m.nf(m.diffDate("D", list.s("sleep_date"), now)));

	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

if("awake".equals(m.rs("mode"))) {
	//휴면해제
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//처리
	int result = userSleep.awakeUser(idx);
	if(0 >= result) {
		m.jsAlert("휴면해제하는 중 오류가 발생했습니다.");
	} else {
		m.jsAlert(result + "명을 휴면해제했습니다.");
	}

	m.jsReplace("../user/sleep_list.jsp?" + m.qs("mode,idx"), "parent");
	return;

} else if("awakeAll".equals(m.rs("mode"))) {
	//휴면해제
	DataSet slist = userSleep.find("1 = 1", "id");

	String[] sidx = new String[slist.size()];
	for(int i = 0; i < slist.size(); i++) {
		slist.next();
		sidx[i] = slist.s("id");
	}
	String idx = "'" + m.join("','", sidx) + "'";
	if("''".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//처리
	int result = userSleep.awakeUser(idx);
	if(0 >= result) {
		m.jsAlert("휴면해제하는 중 오류가 발생했습니다.");
	} else {
		m.jsAlert(result + "명을 휴면해제했습니다.");
	}

	m.jsReplace("../user/sleep_list.jsp?" + m.qs("mode,idx"), "parent");
	return;

} else if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	//엑셀
	ExcelWriter ex = new ExcelWriter(response, "회원휴면관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "login_id=>로그인아이디", "user_nm=>성명", "conn_date_conv=>최근접속일", "sleep_date_conv=>휴면전환일", "reg_date_conv=>등록일", "status_conv=>상태" }, "회원휴면관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("user.sleep_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("id,idx,mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>