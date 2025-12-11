<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(123, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao();
WebtvRecommDao webtvRecomm = new WebtvRecommDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("s_list_mode", "", "hname:'구분', required:'Y'");
f.addElement("s_start_date", m.time("yyyy-MM-01"), "hname:'방송시작일', required:'Y'");
f.addElement("s_end_date", m.time("yyyy-MM-dd"), "hname:'방송종료일', required:'Y'");

//다운로드
if("excel".equals(f.get("mode"))) {

	//기본키
	int wid = m.ri("wid");
	if(1 > wid) return;
	
	//변수
	boolean groupMode = "group".equals(m.rs("s_list_mode"));

	DataSet info = webtv.find("id = ? AND site_id = ? AND status != -1", new Integer[] {wid, siteId});
	if(!info.next()) return;

	DataSet llist = webtvLog.query(
		" SELECT u.*, u.id user_id, a.reg_date log_reg_date, d.dept_nm, r.reg_date recomm_reg_date "
			+ (groupMode ? " , COUNT(*) view_cnt " : "")
		+ " FROM " + webtvLog.table + " a "
			+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
			+ " LEFT JOIN " + webtvRecomm.table + " r ON a.webtv_id = r.webtv_id AND a.user_id = r.user_id "
			+ " LEFT JOIN " + userDept.table + " d ON u.dept_id = d.id "
		+ " WHERE a.webtv_id = " + wid
			//+ " AND a.reg_date >= '" + m.time("yyyyMMdd000000", f.get("s_start_date")) + "'"
			//+ " AND a.reg_date <= '" + m.time("yyyyMMdd235959", f.get("s_end_date")) + "'"
		+ (groupMode ? " GROUP BY u.id " : "")
		+ " ORDER BY a.reg_date DESC "
	);
	while(llist.next()) {
		if(0 < llist.i("dept_id")) {
			llist.put("dept_nm_conv", userDept.getNames(llist.i("dept_id")));
		} else {
			llist.put("dept_nm", "[미소속]");
			llist.put("dept_nm_conv", "[미소속]");
		}
		llist.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", llist.s("log_reg_date")));
		llist.put("view_cnt_conv", m.nf(llist.i("view_cnt")));
		llist.put("recomm_yn", !"".equals(llist.s("recomm_reg_date")));
	}

	//출력
	String title = "방송시청이력-" + m.time("yyyyMMdd-HHmmss", info.s("open_date")) + "-" + info.s("webtv_nm") + "(" + m.time("yyyy-MM-dd") + ")";
	ExcelWriter ex = new ExcelWriter(response, title + ".xls");
	ex.setData(
		llist
		, (groupMode
			? new String[] { "__ord=>No", "dept_nm_conv=>소속", "login_id=>로그인아이디", "user_nm=>회원명", "view_cnt=>시청횟수", "reg_date_conv=>최초시청일자" }
			: new String[] { "__ord=>No", "dept_nm_conv=>소속", "login_id=>로그인아이디", "user_nm=>회원명", "reg_date_conv=>시청일자" }
		), title
	);
	ex.write();
	return;
}

//등록
if(m.isPost()) {

	//폼입력
	boolean groupMode = "group".equals(m.rs("s_list_mode"));

	//변수
	int logCnt = 0;
	
	//webtvLog.d(out);
	DataSet wlist = webtvLog.query(
		" SELECT DISTINCT a.webtv_id, w.* "
		+ " FROM " + webtvLog.table + " a "
		+ " INNER JOIN " + webtv.table + " w ON a.webtv_id = w.id AND w.status != -1 "
		+ " WHERE a.site_id = " + siteId
		+ " AND w.open_date >= '" + m.time("yyyyMMdd000000", f.get("s_start_date")) + "'"
		+ " AND w.open_date <= '" + m.time("yyyyMMdd235959", f.get("s_end_date")) + "'"
		//+ " GROUP BY a.webtv_id "
	);

	//목록
	if("download".equals(f.get("mode"))) {
		while(wlist.next()) {
			//m.jsReplace("테스트", "sysfrmblank");
			m.js("setTimeout(function() {parent.parent.sysfrm.location.href = 'webtv_log_all.jsp?mode=excel&wid=" + wlist.i("webtv_id") + "&s_list_mode=" + f.get("s_list_mode") + "&s_start_date=" + f.get("s_start_date") + "&s_end_date=" + f.get("s_end_date") + "';}, " + (2 * wlist.i("__ord")) + "000);");
		}
		//m.js('parent.document.getElementById("prog").style.display = "none";');
		m.js("setTimeout(function() {alert('다운로드가 완료되었습니다.');}, " + (2 * (wlist.size() + 1)) + "000);");
		m.js("setTimeout(function() {parent.parent.location.href = 'webtv_log_all.jsp';}, " + (2 * (wlist.size() + 2)) + "000);");
		return;

	} else if("search".equals(f.get("mode"))) {

		//출력
		p.setLayout("blank");
		p.setBody("webtv.webtv_log_all");
		p.setVar("query", m.qs());
		p.setVar("list_query", m.qs("id"));
		p.setVar("form_script", f.getScript());

		p.setVar("webtv_count", m.nf(wlist.size()));
		p.setVar("no_block", 1 > wlist.size());

		p.setLoop("list", wlist);
		p.setVar("search_area", true);
		p.display();

		return;
	}
}

//출력
p.setBody("webtv.webtv_log_all");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("form_area", true);
p.display();

%>