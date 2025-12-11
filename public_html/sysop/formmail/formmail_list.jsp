<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(115, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
FormmailDao formmail = new FormmailDao();
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_category_nm", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 10000 : f.getInt("s_listnum", 20) );
lm.setTable(formmail.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.category_nm", f.get("s_category_nm"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(m.rs("s_field"))) lm.addSearch(m.rs("s_field"), f.get("s_keyword").replace("`", "\'"), "LIKE");
else if("".equals(m.rs("s_field")) && !"".equals(m.rs("s_keyword"))) lm.addSearch("a.user_nm,a.email,a.content", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧
DataSet list = lm.getDataSet();
while(list.next()){
	list.put("category_nm_conv", !"".equals(list.s("category_nm")) ? list.s("category_nm") : "-");
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content")), 70));
	list.put("status_conv", m.getItem(list.s("status"), formmail.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? SimpleAES.decrypt(list.s("mobile")) : "-" );
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", "게시판목록", list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", "게시판목록", list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "이메일문의관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "site_id=>사이트아이디", "user_nm=>성명", "mobile_conv=>휴대전화", "email=>이메일", "content=>문의내용", "ip_addr=>아이피", "reg_date_conv=>등록일", "status_conv=>상태" }, "이메일문의관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout(ch);
p.setBody("formmail.formmail_list");
p.setVar("p_title", "이메일문의관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("categories", formmail.query("SELECT DISTINCT category_nm FROM " + formmail.table + " WHERE category_nm IS NOT NULL AND category_nm != '' AND site_id = " + siteId + " AND status != -1 ORDER BY category_nm ASC"));
p.setLoop("status_list", m.arr2loop(formmail.statusList));
p.display();

%>