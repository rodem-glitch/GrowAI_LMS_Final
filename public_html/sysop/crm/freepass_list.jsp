<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FreepassDao freepass = new FreepassDao();
FreepassUserDao freepassUser = new FreepassUserDao();

//제한-회원
if(1 > user.findCount("id = ? AND site_id = " + siteId + " AND status != -1", new Object[] {uid})) { m.jsAlert("해당 회원정보가 없습니다."); return; }

//변수
String today = m.time("yyyyMMdd");

//폼체크
f.addElement("crm_freepass_insert_id", null, "hname:'프리패스등록',required:'Y'");
f.addElement("crm_freepass_insert_nm", null, "hname:'프리패스등록',required:'Y'");

//프리패스신청
if(m.isPost() && f.validate()) {

	//정보
	DataSet finfo = freepass.find("id = " + f.get("crm_freepass_insert_id") + " AND site_id = " + siteId + " AND status != -1");
	if(!finfo.next()) { m.jsAlert("해당 프리패스정보가 없습니다."); return; }

	//신청
	if(!freepassUser.addUser(finfo, f.getInt("uid"), 1)) { m.jsAlert("프리패스를 등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert(f.get("crm_freepass_insert_nm") + "\\n프리패스가 등록되었습니다.");
	m.jsReplace("freepass_list.jsp?uid=" + uid, "parent");
	return;
}

//사용중인 패스
DataSet list1 = freepassUser.query(
	"SELECT a.*, f.freepass_nm "
	+ " FROM " + freepassUser.table + " a "
	+ " INNER JOIN " + freepass.table + " f ON a.freepass_id = f.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 "
	+ " AND a.end_date >= '" + today + "' AND (a.limit_cnt = 0 OR a.use_cnt < a.limit_cnt) "
	+ " ORDER BY a.start_date ASC, a.id DESC "
);
while(list1.next()) {
	list1.put("start_date_conv", m.time("yyyy.MM.dd", list1.s("start_date")));
	list1.put("end_date_conv", m.time("yyyy.MM.dd", list1.s("end_date")));
	list1.put("freepass_nm_conv", m.cutString(list1.s("freepass_nm"), 50));
	list1.put("use_cnt_conv", m.nf(list1.i("use_cnt")));
	list1.put("limit_cnt_conv", (list1.i("limit_cnt") > 0 ? m.nf(list1.i("limit_cnt")) : "무제한"));

	String status = "";
	if(1 > list1.i("status")) status = "중지";
	else if(0 > m.diffDate("D", list1.s("start_date"), today)) status = "사용대기";
	else status = "사용중";

	list1.put("status_conv", status);
}

//종료된 패스
DataSet list2 = freepassUser.query(
	"SELECT a.*, f.freepass_nm "
	+ " FROM " + freepassUser.table + " a "
	+ " INNER JOIN " + freepass.table + " f ON a.freepass_id = f.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 "
	+ " AND (a.end_date < '" + today + "' OR (a.limit_cnt > 0 AND a.use_cnt >= a.limit_cnt)) "
	+ " ORDER BY a.start_date ASC, a.id DESC "
);
while(list2.next()) {
	list2.put("start_date_conv", m.time("yyyy.MM.dd", list2.s("start_date")));
	list2.put("end_date_conv", m.time("yyyy.MM.dd", list2.s("end_date")));
	list2.put("freepass_nm_conv", m.cutString(list2.s("freepass_nm"), 50));
	list2.put("use_cnt_conv", m.nf(list2.i("use_cnt")));
	list2.put("limit_cnt_conv", (list2.i("limit_cnt") > 0 ? m.nf(list2.i("limit_cnt")) : "무제한"));

	String status = "";
	if(1 > list2.i("status")) status = "중지";
	else status = "종료";

	list2.put("status_conv", status);
}

//출력
p.setLayout(ch);
p.setBody("crm.freepass_list");
p.setVar("p_title", "프리패스목록");
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("cuid"));

p.setLoop("list1", list1);
p.setLoop("list2", list2);

p.setVar("tab_coupon", "current");
p.setVar("tab_sub_freepass", "current");
p.display();

%>