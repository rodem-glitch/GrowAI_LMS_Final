<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(112, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
InfoLogDao infoLog = new InfoLogDao(siteId);
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);

f.addElement("s_manager", null, null);
f.addElement("s_type", null, null);
f.addElement("s_category", null, null);

f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
        infoLog.table + " a "
        + " INNER JOIN " + user.table + " b ON a.manager_id = b.id "
);
lm.setFields("a.*, b.id user_id, b.user_kind, b.user_nm, b.login_id, b.status ustatus");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
if(!"".equals(f.get("s_sdate"))) lm.addWhere("a.log_date >= '" + m.time("yyyyMMdd", f.get("s_sdate")) + "'");
if(!"".equals(f.get("s_edate"))) lm.addWhere("a.log_date <= '" + m.time("yyyyMMdd", f.get("s_edate")) + "'");
lm.addSearch("a.manager_id", f.get("s_manager"));
lm.addSearch("a.log_type", f.get("s_type"));
lm.addSearch("a.log_cate", f.get("s_category"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.page_nm,a.purpose,a.ip_addr,b.user_nm,b.login_id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");


//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("log_date_conv", m.time("yyyy.MM.dd", list.s("log_date")));
    list.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("mod_date")));
    list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));

    list.put("log_type_conv", m.getItem(list.s("log_type"), infoLog.types));
    list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));

    String login_id = list.s("login_id");
    if(list.i("ustatus") == -1) login_id = "탈퇴회원";
    if(list.i("ustatus") == -99) login_id = "삭제된회원";

    list.put("login_id", login_id);
    //list.put("login_id", user.getLoginId(list.s("login_id"), list.i("ustatus")));
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
    ExcelWriter ex = new ExcelWriter(response, "개인정보조회기록(" + m.time("yyyy-MM-dd") + ")." + userName + ".xls");
    ex.setData(list, new String[] { "__ord=>No", "log_date=>로그일", "log_type_conv=>유형", "page_nm=>페이지명", "page_path=>페이지경로", "user_cnt=>회원수", "purpose=>목적", "memo=>메모", "user_nm=>조회자명", "login_id=>조회자아이디", "ip_addr=>아이디주소", "mod_date_conv=>수정일", "reg_date_conv=>등록일" }, "개인정보조회기록(" + m.time("yyyy-MM-dd") + ")");
    ex.write();
    return;
}

//출력
p.setBody("policy.log_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("managers", infoLog.getManagers());

p.setLoop("types", m.arr2loop(infoLog.types));
p.setLoop("categories", m.arr2loop(infoLog.categories));
p.display();

%>