<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(19, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(); user.setInsertIgnore(true);
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("code_yn", "N", "hname:'회원소속코드 사용여부'");
f.addElement("dept_id", null, "hname:'회원소속', required:'Y'");
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost()) {

	//배열
	String[] fields = { "col0=>login_id", "col1=>user_nm", "col2=>passwd", "col3=>email", "col4=>mobile", "col5=>birthday", "col6=>gender", "col7=>dept_id", "col8=>zipcode", "col9=>new_addr", "col10=>addr_dtl", "col11=>reg_date", "col12=>etc1", "col13=>etc2", "col14=>etc3", "col15=>etc4", "col16=>etc5"};

	String[] required = { "col0", "col2" };

	String path = dataDir + "/tmp/user.xls";
	File f1 = f.saveFile("file", path);
	if(f1 == null) {
		m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
		return;
	}

	DataSet records = new DataSet();

	records = new ExcelReader(path).getDataSet(1);

	if(!"".equals(path)) m.delFile(path);

	Hashtable<String, Integer> deptCodeMap = new Hashtable<String, Integer>();
	Hashtable<Integer, String> deptNameMap = new Hashtable<Integer, String>();
	DataSet dlist = userDept.find("site_id = " + siteId + " AND status = 1");
	while(dlist.next()) {
		int deptId = dlist.i("id");
		String deptCd = dlist.s("dept_cd");

		if(deptCd.startsWith("|")) deptCd = deptCd.substring(1);
		if(deptCd.endsWith("|")) deptCd = deptCd.substring(0, deptCd.length() - 1);

		String[] temp = m.split("|", deptCd);
		for(int i = 0; i < temp.length; i++) {
			deptCodeMap.put(temp[i], deptId);
		}
		deptNameMap.put(deptId, dlist.s("dept_nm"));
	}

	//목록
	if("register".equals(f.get("mode"))) {

		//변수
		int success = 0;

		//폼입력
		user.item("site_id", siteId);
		user.item("conn_date", m.time("yyyyMMddHHmmss"));
		user.item("reg_date", m.time("yyyyMMddHHmmss"));
		user.item("status", 1);
		user.item("user_kind", "U"); //회원

		int i = 0;
		while(records.next()) {
			boolean flag = true;
			for(int j = 0; j < required.length; j++) {
				if("".equals(records.s(required[j]))) flag = false;
			}

			//if(flag) flag = 0 == user.findCount("login_id = '" + records.s("col0") + "'");

			if(flag) {

				if("Y".equals(f.get("code_yn"))) records.put("col7", deptCodeMap.containsKey(records.s("col7")) ? deptCodeMap.get(records.s("col7")).intValue() : 0);
				int deptId = deptNameMap.containsKey(records.i("col7")) ? records.i("col7") : f.getInt("dept_id");
				/*
				int deptId = (
					records.i("col7") > 0 && 0 < userDept.findCount("id = " + records.i("col7") + " AND site_id = " + siteId + " AND status = 1")
					? records.i("col7")
					: f.getInt("dept_id")
				);
				*/
				String birthday = (8 != records.s("col5").length() ? m.time("yyyyMMdd") : m.time("yyyyMMdd", records.s("col5")));
				String regDate = (19 != records.s("col11").length() ? m.time("yyyyMMddHHmmss") : m.time("yyyyMMddHHmmss", records.s("col11")));

				user.item("dept_id", deptId);
				user.item("login_id", records.s("col0").toLowerCase());
				user.item("user_nm", records.s("col1"));
				user.item("passwd", m.encrypt(records.s("col2"), "SHA-256"));
				user.item("email", records.s("col3"));
				user.item("mobile", !"".equals(records.s("col4")) ? records.s("col4") : "");
				user.item("zipcode", records.s("col8"));
				user.item("addr", "");
				user.item("new_addr", records.s("col9"));
				user.item("addr_dtl", records.s("col10"));
				user.item("gender", !"".equals(records.s("col6")) ? records.s("col6") : "1");
				user.item("birthday", birthday);
				user.item("conn_date", regDate);
				user.item("reg_date", regDate);
				user.item("etc1", records.s("col12"));
				user.item("etc2", records.s("col13"));
				user.item("etc3", records.s("col14"));
				user.item("etc4", records.s("col15"));
				user.item("etc5", records.s("col16"));
				user.item("email_yn", "N");
				user.item("sms_yn", "N");
				user.item("privacy_yn", "N");
				user.item("passwd_date", sysToday);

				if(user.insert()) success++;
			}
		}

		m.jsAlert("총 " + success + "개가 등록됐습니다.\\n등록된 데이터를 확인해주세요.");

		m.jsReplace("user_list.jsp", "parent");
		return;

	} else if("list".equals(f.get("mode"))) {

		//포맷팅
		DataSet list = new DataSet();
		DataSet tmp = m.arr2loop(fields);
		int i = 0;
		while(records.next()) {
			boolean flag = true;
			for(int j = 0; j < required.length; j++) {
				if("".equals(records.s(required[j]))) flag = false;
			}

			if(flag) {
				tmp.first();
				while(tmp.next()) {
					records.put(tmp.s("name"), records.s(tmp.s("id")));
				}

				if("Y".equals(f.get("code_yn"))) records.put("dept_id", deptCodeMap.containsKey(records.s("dept_id")) ? deptCodeMap.get(records.s("dept_id")).intValue() : 0);
				int deptId = deptNameMap.containsKey(records.i("dept_id")) ? records.i("dept_id") : f.getInt("dept_id");
				/*
				int deptId = (
					records.i("dept_id") > 0 && 0 < userDept.findCount("id = " + records.i("dept_id") + " AND site_id = " + siteId + " AND status = 1")
					? records.i("dept_id")
					: f.getInt("dept_id")
				);
				*/
				records.put("dept_id", deptId);
				//records.put("dept_nm_conv", userDept.getNames(deptId));
				records.put("dept_nm_conv", deptNameMap.get(deptId));
				records.put("gender_conv", m.getItem(!"".equals(records.s("gender")) ? records.s("gender") : "1", user.genders));
				records.put("__ord", ++i);

				list.addRow(records.getRow());
			}
			if(i == 20) break;
		}

		//출력
		p.setLayout("blank");
		p.setBody("user.user_excel");
		p.setVar("query", m.qs());
		p.setVar("list_query", m.qs("id"));
		p.setVar("form_script", f.getScript());
		p.setVar("dept_id", f.get("dept_id"));
		p.setVar("code_yn", f.get("code_yn"));

		p.setLoop("list", list);
		p.setVar("list_area", true);
		p.display();

		return;
	}
}

//출력
p.setBody("user.user_excel");
p.setVar("p_title", "회원일괄 등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("dept_list", userDept.getList(siteId));
p.setVar("upload_area", true);
p.display();

%>