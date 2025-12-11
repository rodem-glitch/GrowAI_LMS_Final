<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(929, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
LmCategoryDao category = new LmCategoryDao("webtv");
MCal mcal = new MCal(10);

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("sd", m.time("yyyy-MM-dd", today));
dinfo.put("ed", m.time("yyyy-MM-dd", today));
dinfo.put("sw", m.time("yyyy-MM-dd", mcal.getWeekFirstDate(today)));
dinfo.put("ew", m.time("yyyy-MM-dd", mcal.getWeekLastDate(today)));
dinfo.put("sm", m.time("yyyy-MM-01", today));
dinfo.put("em", m.time("yyyy-MM-dd", mcal.getMonthLastDate(today)));
dinfo.put("sy", m.time("yyyy-01-01", today));
dinfo.put("ey", m.time("yyyy-12-31", today));
dinfo.put("s3y", m.time("yyyy-01-01", m.addDate("Y", -2, today, "yyyyMMdd")));
dinfo.put("e3y", m.time("yyyy-12-31", today));

//폼입력
String sdate = m.rs("s_view_sdate", dinfo.s("sm"));
String edate = m.rs("s_view_edate", dinfo.s("em"));

//폼입력
f.addElement("s_view_sdate", sdate, "hname:'시청시작일'");
f.addElement("s_view_edate", edate, "hname:'시청종료일'");

dinfo.put("sdate_conv", m.time("yyyy.MM.dd", sdate));
dinfo.put("edate_conv", m.time("yyyy.MM.dd", edate));

//카테고리
DataSet categories = category.getList(siteId);

//목록-로그
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20000);
lm.setTable(
	webtvLog.table + " a "
	+ " INNER JOIN " + webtv.table + " w ON a.webtv_id = w.id AND w.site_id = " + siteId + " AND w.status != -1 "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
);
lm.setFields("u.dept_id, COUNT(*) view_cnt");
lm.addWhere("u.status != -1");
lm.addWhere("u.site_id = " + siteId);
if(!"".equals(sdate)) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", sdate) + "'");
if(!"".equals(edate)) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", edate) + "'");
lm.setGroupBy("u.dept_id");

//포멧팅
Hashtable<String, Integer> deptMap = new Hashtable<String, Integer>();
DataSet llist = lm.getDataSet();
while(llist.next()) {
	String key = llist.s("dept_id");
	if(!deptMap.containsKey(key)) {
		deptMap.put(key, llist.i("view_cnt"));
	}
}

//목록-소속
int sumTotalCount = 0;
DataSet list = userDept.getAllList(siteId);
list.addRow();
list.put("id", "0");
list.put("name_conv", "[미소속]");
list.first();
while(list.next()) {
	String key = list.s("id");
	list.put("view_cnt", deptMap.containsKey(key) ? deptMap.get(key).intValue() : 0);
	list.put("view_cnt_conv", m.nf(list.i("view_cnt")));
	
	sumTotalCount += list.i("view_cnt");
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "소속별시청통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "id=>소속ID", "name_conv=>소속명", "view_cnt=>시청횟수" }, "소속별시청통계(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.webtv_dept");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("sum_total_count", m.nf(sumTotalCount));

p.setVar("date", dinfo);
p.display();

%>