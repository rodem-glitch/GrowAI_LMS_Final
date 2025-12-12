<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(16, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("login_id", null, "hname:'회원아이디', required:'Y'");
f.addElement("dept_id", null, "hnaMe:'소속', required:'Y'");
f.addElement("user_nm", null, "hname:'강사명', required:'Y'");
f.addElement("name_en", null, "hname:'강사명(영문)', required:'Y'");
f.addElement("passwd", null, "hname:'비밀번호', required:'Y', match:'passwd2', minbyte:'9', maxbyte:'20'");
f.addElement("gender", 1, "hname:'성별', required:'Y'");
f.addElement("birthday", null, "hname:'생년월일'");
f.addElement("mobile", null, "hname:'휴대전화'");
f.addElement("email1", null, "hname:'이메일', required:'Y', option:'email', glue:'email2', delim:'@'");
f.addElement("email2", null, "hname:'이메일', required:'Y'");
f.addElement("zipcode", null, "hname:'우편번호'");
//f.addElement("addr", null, "hname:'구주소'");
f.addElement("new_addr", null, "hname:'주소'");
f.addElement("addr_dtl", null, "hname:'상세주소'");
f.addElement("etc1", null, "hname:'기타1'");
f.addElement("etc2", null, "hname:'기타2'");
f.addElement("etc3", null, "hname:'기타3'");
f.addElement("etc4", null, "hname:'기타4'");
f.addElement("etc5", null, "hname:'기타5'");

f.addElement("display_yn", null, "hname:'강사노출여부'");
f.addElement("attached", null, "hname:'소속'");
f.addElement("ability", null, "hname:'경력사항', allowhtml:'Y'");
f.addElement("major", null, "hname:'전공'");
f.addElement("university", null, "hname:'최종학력'");
f.addElement("introduce", null, "hname:'소개', allowhtml:'Y'");
f.addElement("bank_nm", null, "hname:'은행명'");
f.addElement("bank_account", null, "hname:'계좌번호'");
f.addElement("tutor_file", null, "hname:'사진', allow:'jpg|gif|jpeg|png'");
f.addElement("status", 1, "hname:'상태', required:'Y'");


//등록
if(m.isPost() && f.validate()) {

	//제한
	if(user.findCount("login_id = '" + f.get("login_id").toLowerCase() + "' AND site_id = " + siteId + "") > 0) {
		m.jsError("이미 사용 중인 아이디입니다.");
		return;
	}

	//제한-비밀번호
	if(!f.get("passwd").matches("^(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[\\W_]).{9,}$")) {
		m.jsAlert("비밀번호는 영문, 숫자, 특수문자 조합 9자 이상 입력하세요.");
		return;
	}

	//제한-이미지URI및용량
	String ability = f.get("ability");
	String introduce = f.get("introduce");
	int byteab = ability.replace("\r\n", "\n").getBytes("UTF-8").length;
	int bytein = introduce.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < ability.indexOf("<img") && -1 < ability.indexOf("data:image/") && -1 < ability.indexOf("base64")) {
		m.jsAlert("경력 사항 이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(-1 < introduce.indexOf("<img") && -1 < introduce.indexOf("data:image/") && -1 < introduce.indexOf("base64")) {
		m.jsAlert("강사 소개 이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(60000 < byteab) { m.jsAlert("경력 사항 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + byteab + "바이트)"); return; }
	if(60000 < bytein) { m.jsAlert("강사 소개 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytein + "바이트)"); return; }

	//변수-이메일
	String email = f.glue("@", "email1, email2");
	if("@".equals(email)) email = "";

	int newId = user.getSequence();
	user.item("id", newId);
	user.item("login_id", f.get("login_id").toLowerCase());
	user.item("dept_id", f.get("dept_id"));
	user.item("site_id", siteId);
	user.item("user_kind", "U");
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
	user.item("tutor_yn", "Y");
	user.item("display_yn", f.get("display_yn", "N"));
	user.item("conn_date", m.time("yyyyMMddHHmmss"));
	user.item("reg_date", m.time("yyyyMMddHHmmss"));
	user.item("status", f.getInt("status"));
	user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));
	//FAIL_CNT는 로그인 실패횟수로 TB_USER에서 NOT NULL입니다. 강사 등록도 0에서 시작하도록 기본값을 넣어줍니다.
	user.item("fail_cnt", 0);

	if(!user.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	tutor.item("user_id", newId);
	tutor.item("site_id", siteId);
	tutor.item("tutor_nm", f.get("user_nm"));
	tutor.item("name_en", f.get("name_en"));
	tutor.item("attached", f.get("attached"));

	if(null != f.getFileName("tutor_file")) {
		File f1 = f.saveFile("tutor_file");
		if(f1 != null) tutor.item("tutor_file", f.getFileName("tutor_file"));
	}

	tutor.item("ability", f.get("ability"));
	tutor.item("university", f.get("university"));
	tutor.item("major", f.get("major"));
	tutor.item("introduce", f.get("introduce"));
	tutor.item("bank_nm", f.get("bank_nm"));
	tutor.item("bank_account", f.get("bank_account"));
	tutor.item("status", f.getInt("status"));

	if(!tutor.insert()) {
		//Rollback
		if(-1 == user.execute("DELETE FROM " + user.table + " WHERE id = " + newId + "")) {}

		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	//기록-개인정보조회
	_log.add("C", Menu.menuNm, 1, "이러닝 운영");

	//이동
	m.jsReplace("tutor_list.jsp?" + m.qs("id"), "parent");
	return;

}

//출력
p.setBody("user.tutor_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("SITE_CONFIG", SiteConfig.getArr(new String[] {"user_etc_", "join_"}));

p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("genders", m.arr2loop(user.genders));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>
