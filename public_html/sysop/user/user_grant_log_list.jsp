<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(142, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ActionLogDao actionLog = new ActionLogDao();
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
    actionLog.table + " a "
    + " INNER JOIN " + user.table + " u ON a.module_id = u.id "
    + " INNER JOIN " + user.table + " m ON a.user_id = m.id "
);
lm.setFields("a.*, u.user_nm, u.login_id, m.user_nm manager_nm, m.login_id manager_login_id");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.module = 'user_grant'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("u.user_nm,m.user_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");


//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
    list.put("before_info_conv", m.cutString(list.s("before_info"), 50));
    list.put("after_info_conv", m.cutString(list.s("after_info"), 50));
    user.maskInfo(list);
}

//엑셀
if("excel".equals(m.rs("mode"))) {
    ExcelWriter ex = new ExcelWriter(response, "개인정보조회기록(" + m.time("yyyy-MM-dd") + ")." + userName + ".xls");
    ex.setData(list, new String[] { "__ord=>No", "log_date=>로그일", "log_type_conv=>유형", "page_nm=>페이지명", "page_path=>페이지경로", "user_cnt=>회원수", "purpose=>목적", "memo=>메모", "user_nm=>조회자명", "login_id=>조회자아이디", "ip_addr=>아이디주소", "mod_date_conv=>수정일", "reg_date_conv=>등록일" }, "개인정보조회기록(" + m.time("yyyy-MM-dd") + ")");
    ex.write();
    return;
}

//출력
p.setBody("user.user_grant_log_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>