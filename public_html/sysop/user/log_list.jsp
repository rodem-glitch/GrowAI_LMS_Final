<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!isMalgnOffice) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserLogDao userLog = new UserLogDao();
UserDao user = new UserDao();

//폼체크
f.addElement("s_type", null, null);
f.addElement("s_module", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? sysExcelCnt : 20);
lm.setTable(
    userLog.table + " a "
    + " LEFT JOIN " + user.table + " m ON a.user_id = m.id AND m.site_id = a.site_id "
);
lm.setFields("a.*, m.login_id, m.user_nm, m.status ustatus");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
lm.addSearch("a.action_type", f.get("s_type"));
lm.addSearch("a.module", f.get("s_module"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
    lm.addSearch("a.action_desc,a.before_info,a.after_info", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("action_type_conv", Malgn.getItem(list.s("action_type"), userLog.types));
    list.put("module_conv", Malgn.getItem(list.s("module"), userLog.modules));
    list.put("reg_date_conv", Malgn.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
    list.put("before_info", Malgn.htt(list.s("before_info")));
    list.put("after_info", Malgn.htt(list.s("after_info")));
    list.put("before_info", Malgn.cutString(list.s("before_info"), 55));
    list.put("after_info", Malgn.cutString(list.s("after_info"), 55));
}


//출력
p.setLayout(ch);
p.setBody("user.log_list");
p.setVar("p_title", "회원로그관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("list_total_num", Malgn.nf(lm.getTotalNum()));

p.setLoop("types", Malgn.arr2loop(userLog.types));
p.setLoop("modules", Malgn.arr2loop(userLog.modules));
p.setLoop("status_list", Malgn.arr2loop(userLog.statusList));

p.display();

%>