<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
if(courseId == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
CourseUserDao courseUser = new CourseUserDao();

//폼체크
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//처리
if(m.isPost()) {

	//등록
	if("register".equals(f.get("mode"))) {
		//변수
		int success = 0;
		int failed = 0;
		StringBuffer failedUser = new StringBuffer();

		//등록
		String[] idx = f.getArr("idx");
		for(int i = 0; i < idx.length; i++) {
			int uid = m.parseInt(idx[i]) - 1;
			int courseUserId = Integer.parseInt(f.getArr("id")[uid]);
			String courseUserLoginId = f.getArr("login_id")[uid];
			String courseUserStartDate = alltime ? f.getArr("start_date")[uid] : "";
			String courseUserEndDate = alltime ? f.getArr("end_date")[uid] : "";

			if(courseUser.addUser(cinfo, courseUserId, 1, courseUserStartDate, courseUserEndDate)) {
				success++;
			} else {
				failedUser.append("\\n" + ++failed + ". [" + courseUserId + "] " + courseUserLoginId);
			}
		}

		m.jsAlert("총 " + idx.length + "명 중 " + success + "명이 등록되었습니다." + (0 < failed ? "\\n\\n[등록 실패 아이디]" + failedUser.toString() : ""));
		m.jsReplace("user_list.jsp?" + m.qs("mode"), "parent");
		return;

	//파일
	} else if(f.validate() && "list".equals(f.get("mode"))) {

		File f1 = f.saveFile("file");
		if(f1 != null) {
			String path = m.getUploadPath(f.getFileName("file"));
			DataSet records = new DataSet();

			records = new ExcelReader(path).getDataSet(1);

			if(!"".equals(path)) m.delFileRoot(path);

			//포맷팅
			String[] idx = new String[records.size()];
			HashMap<String, String> sdateList = new HashMap<String, String>();
			HashMap<String, String> edateList = new HashMap<String, String>();
			while(records.next()) {
				idx[records.getIndex()] = records.s("col0");
				sdateList.put(records.s("col0"), (8 != records.s("col2").length() ? "" : m.time("yyyyMMdd", records.s("col2"))));
				edateList.put(records.s("col0"), (8 != records.s("col3").length() ? "" : m.time("yyyyMMdd", records.s("col3"))));
			}

			//목록
			DataSet list = user.query(
				" SELECT a.*, d.dept_nm "
				+ " FROM " + user.table + " a "
				+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
				+ " WHERE a.site_id = " + siteId + " AND a.login_id IN ('" + m.join("', '", idx) + "') AND a.status = 1 "
			);
			while(list.next()) {
				if(0 < list.i("dept_id")) {	
					list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
				} else {	
					list.put("dept_nm", "[미소속]");
					list.put("dept_nm_conv", "[미소속]");
				}

				list.put("start_date", (sdateList.containsKey(list.s("login_id")) ? sdateList.get(list.s("login_id")) : ""));
				list.put("end_date", (edateList.containsKey(list.s("login_id")) ? edateList.get(list.s("login_id")) : ""));
				list.put("study_date_conv"
					, (!"".equals(list.s("start_date")) && !"".equals(list.s("end_date"))
					? m.time("yyyy.MM.dd", list.s("start_date")) + " - " + m.time("yyyy.MM.dd", list.s("end_date"))
					: m.time("yyyy.MM.dd") + " - " + m.time("yyyy.MM.dd", m.addDate("D", cinfo.i("lesson_day") > 0 ? cinfo.i("lesson_day")-1 : 0, m.time("yyyyMMdd")))
				));
				list.put("mobile_conv", list.s("mobile"));
			}

			//출력
			p.setLayout("blank");
			p.setBody("management.user_excel");
			p.setVar("query", m.qs());
			p.setVar("list_query", m.qs("id"));
			p.setVar("form_script", f.getScript());

			p.setLoop("list", list);
			p.setVar("list_total", list.size());
			p.setVar("list_area", true);

			p.display();

			return;
		} else {
			m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
			return;
		}
	}
}

//출력
p.setBody("management.user_excel");
p.setVar("p_title", "수강생일괄추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(cinfo);

p.setVar("upload_area", true);
p.display();

%>