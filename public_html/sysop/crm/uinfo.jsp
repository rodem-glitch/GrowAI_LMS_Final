<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
//UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = user.query(
	"SELECT a.*, d.dept_nm "
	+ " FROM " + user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
	+ " WHERE a.id = " + uid + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), user.statusList));
info.put("gender_conv", m.getItem(info.s("gender"), user.genders));
info.put("mobile", !"".equals(info.s("mobile")) ? info.s("mobile") : "-");
info.put("login_block", "U".equals(info.s("user_kind")));

//출력
p.setBody("crm.uinfo");
p.setVar("p_title", "회원기본정보");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("modify", true);
p.setVar(info);

p.setVar("ek", m.encrypt(uid + siteinfo.s("domain") + m.time("yyyyMMdd")));
p.print(out, "crm/uinfo.html");

%>