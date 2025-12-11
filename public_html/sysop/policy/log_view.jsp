<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(138, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
InfoLogDao infoLog = new InfoLogDao(siteId);
InfoUserDao logUser = new InfoUserDao(siteId);
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = infoLog.query(
        "SELECT a.*, b.id user_id, b.user_kind, b.user_nm, b.login_id, b.status ustatus "
        + " FROM " + infoLog.table + " a "
        + " INNER JOIN " + user.table + " b ON a.manager_id = b.id "
        + " WHERE a.id = " + id + " "
        + " AND a.status != -1 "
        + " AND a.site_id = " + siteId
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("purpose", info.s("purpose"), "hname:'목적'");
f.addElement("memo", info.s("memo"), "hname:'메모'");

//저장
if(m.isPost() && f.validate()) {
    infoLog.item("purpose", f.get("purpose"));
    infoLog.item("memo", f.get("memo"));
    infoLog.item("mod_date", sysNow);
    if(!infoLog.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

    //이동
    m.jsReplace("log_view.jsp?" + m.qs(), "parent");
    return;
}

//포맷팅
info.put("log_date_conv", m.time("yyyy.MM.dd", info.s("log_date")));
info.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("mod_date")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
//info.put("user_cnt_conv", m.nf(info.i("user_cnt")));

info.put("log_type_conv", m.getItem(info.s("log_type"), infoLog.types));
info.put("user_kind_conv", m.getItem(info.s("user_kind"), user.kinds));

//목록
DataSet list = logUser.query(
        "SELECT a.*, c.dept_nm FROM " + logUser.table + " b "
        + " INNER JOIN " + user.table + " a ON b.user_id = a.id "
        + " INNER JOIN " + userDept.table + " c ON a.dept_id = c.id"
        + " WHERE b.log_id = " + id + " "
        + " ORDER BY a.user_nm ASC "
);
while(list.next()) {
    list.put("status_conv", m.getItem(list.s("status"), user.statusList));
    list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
    list.put("company_nm", list.i("company_id") > 0 ? list.s("company_nm") : list.s("company"));
    user.maskInfo(list); //마스킹
    if(list.i("status") == -1) list.put("user_nm", "[탈퇴]");
}

//출력
p.setLayout("poplayer");
p.setBody("policy.log_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("list", list);
p.setVar("user_cnt_conv", list.size());

p.display();

%>