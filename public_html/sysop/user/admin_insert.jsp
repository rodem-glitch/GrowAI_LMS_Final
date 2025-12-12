<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(17, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
MenuDao menu = new MenuDao();
UserMenuDao userMenu = new UserMenuDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("login_id", null, "hname:'관리자아이디', required:'Y'");
f.addElement("dept_id", null, "hnaMe:'소속', required:'Y'");
f.addElement("user_nm", null, "hname:'관리자명', required:'Y'");
f.addElement("user_kind", null, "hname:'유형', required:'Y'");
f.addElement("passwd", null, "hname:'비밀번호', required:'Y', match:'passwd2', minbyte:'9', maxbyte:'20'");
f.addElement("gender", 1, "hname:'성별', required:'Y'");
f.addElement("birthday", null, "hname:'생년월일'");
f.addElement("email1", null, "hname:'이메일', required:'Y', option:'email', glue:'email2', delim:'@'");
f.addElement("email2", null, "hname:'이메일', required:'Y'");
f.addElement("mobile", null, "hname:'휴대전화'");
f.addElement("zipcode", null, "hname:'우편번호'");
//f.addElement("addr", null, "hname:'구주소'");
f.addElement("new_addr", null, "hname:'주소'");
f.addElement("addr_dtl", null, "hname:'상세주소'");
f.addElement("etc1", null, "hname:'기타1'");
f.addElement("etc2", null, "hname:'기타2'");
f.addElement("etc3", null, "hname:'기타3'");
f.addElement("etc4", null, "hname:'기타4'");
f.addElement("etc5", null, "hname:'기타5'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//제한
	if(0 < user.findCount("login_id = '" + f.get("login_id").toLowerCase() + "' AND site_id = " + siteId + "")) {
		m.jsError("이미 사용 중인 아이디입니다.");
		return;
	}

	//제한-비밀번호
	if(!f.get("passwd").matches("^(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[\\W_]).{9,}$")) {
		m.jsAlert("비밀번호는 영문, 숫자, 특수문자 조합 9자 이상 입력하세요.");
		return;
	}

	//변수-이메일
	String email = f.glue("@", "email1, email2");
	if("@".equals(email)) email = "";

	int newId = user.getSequence();
	user.item("id", newId);
	user.item("login_id", f.get("login_id").toLowerCase());
	user.item("dept_id", f.get("dept_id"));
	user.item("site_id", siteId);
	user.item("user_kind", f.get("user_kind"));
	user.item("user_nm", f.get("user_nm"));
	user.item("passwd", m.encrypt(f.get("passwd"), "SHA-256"));
	user.item("email", email);
	user.item("mobile", !"".equals(f.get("mobile")) ? f.get("mobile") : "");
	user.item("zipcode", f.get("zipcode"));
	//user.item("addr", f.get("addr"));
	user.item("new_addr", f.get("new_addr"));
	user.item("addr_dtl", f.get("addr_dtl"));
	user.item("gender", f.getInt("gender"));
	user.item("birthday", m.time("yyyyMMdd", f.get("birthday")));
	user.item("etc1", f.get("etc1"));
	user.item("etc2", f.get("etc2"));
	user.item("etc3", f.get("etc3"));
	user.item("etc4", f.get("etc4"));
	user.item("etc5", f.get("etc5"));
	user.item("conn_date", m.time("yyyyMMddHHmmss"));
	user.item("reg_date", m.time("yyyyMMddHHmmss"));
	user.item("status", f.getInt("status"));
	user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));
	//FAIL_CNT는 로그인 실패횟수로 TB_USER에서 NOT NULL입니다. 운영자 등록도 0에서 시작하도록 기본값을 넣어줍니다.
	user.item("fail_cnt", 0);

	if(!user.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//메뉴-운영자
	if(!"S".equals(f.get("user_kind"))) {
		if(-1 == userMenu.execute(
			"INSERT INTO " + userMenu.table + " "
			+ " SELECT '" + newId + "' user_id, id menu_id, '" + siteId + "' site_id "
			+ " FROM " + menu.table + " "
			+ " WHERE menu_type = 'ADMIN' AND auth_access LIKE '%|" + f.get("user_kind") + "|%' AND status = 1 AND display_yn = 'Y'"
		)) { }
	}

	//기록-개인정보조회
	_log.add("C", Menu.menuNm, 1, "이러닝 운영");

	m.jsReplace("admin_list.jsp?" + m.qs("id"), "parent");
	return;

}

//출력
p.setBody("user.admin_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("SITE_CONFIG", SiteConfig.getArr(new String[] {"user_etc_", "join_"}));

p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("genders", m.arr2loop(user.genders));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>
