<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(142, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(0 == id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ActionLogDao actionLog = new ActionLogDao();
UserDao user = new UserDao(isBlindUser);

//정보
DataSet info = actionLog.query(
        "SELECT a.*, u.user_nm, u.login_id, m.user_nm manager_nm, m.login_id manager_login_id "
        + " FROM " + actionLog.table + " a "
        + " INNER JOIN " + user.table + " u ON a.module_id = u.id AND u.site_id = a.site_id"
        + " INNER JOIN " + user.table + " m ON a.user_id = m.id AND m.site_id = a.site_id"
        + " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
        + " AND module = 'user_grant'"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
user.maskInfo(info);

DataSet blist = new DataSet();
blist.unserialize(info.s("before_info"));
//if(!"".equals(info.s("before_info"))) {
//    DataSet binfo = new DataSet(); binfo.unserialize(info.s("before_info"));
//
//    String[] barr = binfo.getKeys();
//    for(int i = 0; i < barr.length; i++) {
//        blist.addRow();
//        blist.put("item_nm", barr[i]);
//        //blist.put("item_value", binfo.s(barr[i]));
//        blist.put("item_value", m.stripTags(binfo.s(barr[i])));
//    }
//}

DataSet alist = new DataSet();
alist.unserialize(info.s("after_info"));
//if(!"".equals(info.s("after_info"))) {
//    DataSet ainfo = new DataSet(); ainfo.unserialize(info.s("after_info"));
//
//    String[] aarr = ainfo.getKeys();
//    for(int i = 0; i < aarr.length; i++) {
//        alist.addRow();
//        alist.put("item_nm", aarr[i]);
//        //alist.put("item_value", ainfo.s(aarr[i]));
//        alist.put("item_value", m.stripTags(ainfo.s(aarr[i])));
//    }
//}

//출력
p.setLayout("pop");
p.setBody("user.user_grant_log_view");
p.setVar("p_title", "관리자권한이력관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("blist", blist);
p.setLoop("alist", alist);

p.display();

%>