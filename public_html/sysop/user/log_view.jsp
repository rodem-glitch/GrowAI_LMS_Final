<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!isMalgnOffice) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(0 == id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserLogDao userLog = new UserLogDao();
UserDao user = new UserDao();

//정보
DataSet info = userLog.query(
    "SELECT a.*, m.user_nm manager_nm, m.login_id "
    + " FROM " + userLog.table + " a "
    + " LEFT JOIN " + user.table + " m ON a.user_id = m.id AND m.site_id = a.site_id"
    + " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("action_type_conv", m.getItem(info.s("action_type"), userLog.types));
info.put("module_conv", m.getItem(info.s("module"), userLog.modules));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));

DataSet blist = new DataSet();
if(!"".equals(info.s("before_info"))) {
    DataSet binfo = new DataSet(); binfo.unserialize(info.s("before_info"));

    String[] barr = binfo.getKeys();
    for(int i = 0; i < barr.length; i++) {
        blist.addRow();
        blist.put("item_nm", barr[i]);
        //blist.put("item_value", binfo.s(barr[i]));
        blist.put("item_value", m.stripTags(binfo.s(barr[i])));
    }
}

DataSet alist = new DataSet();
if(!"".equals(info.s("after_info"))) {
    DataSet ainfo = new DataSet(); ainfo.unserialize(info.s("after_info"));

    String[] aarr = ainfo.getKeys();
    for(int i = 0; i < aarr.length; i++) {
        alist.addRow();
        alist.put("item_nm", aarr[i]);
        //alist.put("item_value", ainfo.s(aarr[i]));
        alist.put("item_value", m.stripTags(ainfo.s(aarr[i])));
    }
}

//출력
p.setLayout("pop");
p.setBody("user.log_view");
p.setVar("p_title", "작업로그관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("blist", blist);
p.setLoop("alist", alist);

p.setLoop("types", m.arr2loop(userLog.types));
p.setLoop("modules", m.arr2loop(userLog.modules));
p.setLoop("status_list", m.arr2loop(userLog.statusList));
p.display();

%>