<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int courseId = m.ri("cid");
if(courseId == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//정보
DataSet cinfo = course.find(
	"id = " + courseId + " AND site_id = " + siteId + " AND status != -1"
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }

//폼체크
f.addElement("mode3", "text", "hname:'입력방식', required:'Y'");
f.addElement("file", null, "hname:'파일', allow:'xls'");

//처리
if(m.isPost()) {

	//등록
	if("register".equals(f.get("mode2"))) {
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
			String courseUserStartDate = ("A".equals(cinfo.s("course_type"))) ? m.time("yyyyMMdd", f.getArr("start_date")[uid]) : "";
			String courseUserEndDate = ("A".equals(cinfo.s("course_type"))) ? m.time("yyyyMMdd", f.getArr("end_date")[uid]) : "";

			if(courseUser.addUser(cinfo, courseUserId, 1, courseUserStartDate, courseUserEndDate)) {
				success++;
			} else {
				failedUser.append("\\n" + ++failed + ". [" + courseUserId + "] " + courseUserLoginId);
			}
		}

		m.jsAlert("총 " + idx.length + "명 중 " + success + "명이 등록되었습니다." + (0 < failed ? "\\n\\n[등록 실패 아이디]" + failedUser.toString() : ""));
		m.jsReplace("user_list.jsp?" + m.qs("mode2"), "parent");
		return;

	//업로드
	} else if(f.validate() && "list".equals(f.get("mode2"))) {

		//변수
		String[] idx = null;
		HashMap<String, String> sdateList = new HashMap<String, String>();
		HashMap<String, String> edateList = new HashMap<String, String>();

		if("text".equals(f.get("mode3"))) {
			//텍스트입력
			idx = m.split("\r\n", f.get("login_idx"));

		} else if("file".equals(f.get("mode3"))) {
			//엑셀파일
			File f1 = f.saveFile("file");
			if(f1 != null) {
				DataSet records = new DataSet();
				String path = m.getUploadPath(f.getFileName("file"));

				records = new ExcelReader(path).getDataSet(1);

				if(!"".equals(path)) m.delFileRoot(path);

				//포맷팅
				idx = new String[records.size()];
				while(records.next()) {
					idx[records.getIndex()] = records.s("col0");
					sdateList.put(records.s("col0"), (8 != records.s("col2").length() ? "" : m.time("yyyyMMdd", records.s("col2"))));
					edateList.put(records.s("col0"), (8 != records.s("col3").length() ? "" : m.time("yyyyMMdd", records.s("col3"))));
				}

			} else {
				m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
				return;
			}
			
		}
		
		//제한
		if(idx == null) { m.jsAlert("해당 회원 정보가 없습니다."); return; }

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
			if("".equals(list.s("start_date")) || "".equals(list.s("end_date"))) {
				list.put("start_date", m.time("yyyyMMdd"));
				list.put("end_date", m.addDate("D", cinfo.i("lesson_day") > 0 ? cinfo.i("lesson_day") - 1 : 0, m.time("yyyyMMdd"), "yyyyMMdd"));
			}
			list.put("start_date_conv", m.time("yyyy-MM-dd", list.s("start_date")));
			list.put("end_date_conv", m.time("yyyy-MM-dd", list.s("end_date")));
			list.put("mobile_conv", list.s("mobile"));
		}

		//출력
		p.setLayout("blank");
		p.setBody("course.user_excel");
		p.setVar("query", m.qs());
		p.setVar("list_query", m.qs("id"));
		p.setVar("form_script", f.getScript());

		p.setLoop("list", list);
		p.setVar("list_total", list.size());
		p.setVar("list_area", true);

		p.display();

		return;
	}
}

//출력
p.setLayout("sysop");
p.setBody("course.user_excel");
p.setVar("p_title", "수강생일괄등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(cinfo);

p.setVar("upload_area", true);
p.display();

%>