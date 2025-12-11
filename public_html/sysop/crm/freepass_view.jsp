<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int fuid = m.ri("fuid");
if(fuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
FreepassDao freepass = new FreepassDao();
FreepassUserDao freepassUser = new FreepassUserDao();

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//정보-수강생
DataSet fuinfo = freepassUser.query(
	"SELECT a.* "
	+ ", (CASE WHEN '" + today + "' BETWEEN a.start_date AND a.end_date THEN 'Y' ELSE 'N' END) is_available "
	+ ", u.user_nm, u.login_id "
	+ " FROM " + freepassUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
	+ " WHERE a.id = " + fuid + " AND a.user_id = " + uid + " "
);
if(!fuinfo.next()) { m.jsError("해당 수강생정보가 없습니다."); return; }
int fid = fuinfo.i("freepass_id");

//정보-프리패스
DataSet finfo = freepass.find("id = " + fid + " AND site_id = " + siteId + " AND status != -1");
if(!finfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }

//폼체크
f.addElement("limit_cnt", fuinfo.i("limit_cnt"), "hname:'제한횟수', required:'Y', option:'number', min:'0', max:'999'");
f.addElement("start_date", null, "hname:'사용시작일', required:'Y'");
f.addElement("end_date", null, "hname:'사용종료일', required:'Y'");
f.addElement("status", fuinfo.s("status"), "hname:'상태', required:'Y'");

//수정-사용기간
if(m.isPost() && f.validate()) {

	freepassUser.item("limit_cnt", f.getInt("limit_cnt"));
	freepassUser.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	freepassUser.item("end_date", m.time("yyyyMMdd",f.get("end_date")));
	freepassUser.item("status", f.get("status"));
	if(!freepassUser.update("id = " + fuid + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("freepass_view.jsp?" + m.qs());
	return;
}

//포맷팅
fuinfo.put("start_date_conv", m.time("yyyy-MM-dd", fuinfo.s("start_date")));
fuinfo.put("end_date_conv", m.time("yyyy-MM-dd", fuinfo.s("end_date")));
fuinfo.put("freepass_nm_conv", m.cutString(fuinfo.s("freepass_nm"), 50));
fuinfo.put("use_cnt_conv", m.nf(fuinfo.i("use_cnt")));
fuinfo.put("limit_cnt_conv", (fuinfo.i("limit_cnt") > 0 ? m.nf(fuinfo.i("limit_cnt")) : "무제한"));
fuinfo.put("status_conv", m.getItem(fuinfo.s("status"), freepassUser.statusList));

//목록-로그
//orderItem.d(out);
Hashtable<String, Integer> orderCountMap = new Hashtable<String, Integer>();
DataSet logs = orderItem.query(
	" SELECT a.id, a.order_id, a.course_id, a.status order_item_status, o.pay_date, o.reg_date order_date "
	+ " , c.course_nm, c.onoff_type, c.restudy_yn, c.restudy_day, c.year, c.step "
	+ " FROM " + orderItem.table + " a "
	+ " INNER JOIN " + order.table + " o ON a.order_id = o.id "
//	+ " INNER JOIN " + courseUser.table + " cu ON a.id = cu.order_item_id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.freepass_user_id = " + fuid + " AND a.status IN (1,2,10,20) "
	+ " ORDER BY a.order_id ASC, a.id ASC "
);
while(logs.next()) {
	//logs.put("order_item_cnt");
	logs.put("order_date_conv", m.time("yyyy.MM.dd HH:mm", logs.s("order_date")));
	logs.put("study_date_conv", logs.s("start_date_conv") + " - " + logs.s("end_date_conv"));
	logs.put("course_nm_conv", m.cutString(logs.s("course_nm"), 50));
	logs.put("progress_ratio", m.nf(logs.d("progress_ratio"), 1));
	logs.put("total_score", m.nf(logs.d("total_score"), 1));
	logs.put("onoff_type_conv", m.getItem(logs.s("onoff_type"), course.onoffPackageTypes));
	logs.put("order_item_status_conv", m.getItem(logs.s("order_item_status"), orderItem.statusList));

	String key = logs.s("order_id");
	logs.put("order_first_block", false);
	if(!orderCountMap.containsKey(key)) {
		logs.put("order_first_block", true);
		orderCountMap.put(key, 1);
	} else {
		orderCountMap.put(key, orderCountMap.get(key) + 1);
	}
}
logs.first();
while(logs.next()) {
	String key = logs.s("order_id");
	if(logs.b("order_first_block") && orderCountMap.containsKey(key)) {
		logs.put("order_rowspan", orderCountMap.get(key));
	} else {
		logs.put("order_rowspan", 0);
	}
}

//출력
p.setLayout(ch);
p.setBody("crm.freepass_view");
p.setVar("p_title", "프리패스정보");
p.setVar("form_script", f.getScript());
p.setVar("mode_query", m.qs("mode"));
p.setVar("list_query", m.qs("fuid,mode"));
p.setVar("query", m.qs());

p.setVar("freepass", finfo);
p.setVar("fuinfo", fuinfo);
p.setLoop("logs", logs);

p.setVar("tab_coupon", "current");
p.setVar("tab_sub_freepass", "current");
p.setLoop("status_list", m.arr2loop(freepassUser.statusList));
p.display();

%>