<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookDao book = new BookDao();
BookTargetDao bookTarget = new BookTargetDao();
BookRelateDao bookRelate = new BookRelateDao();
BookPackageDao bookPackage = new BookPackageDao();
UserDao user = new UserDao();
LessonDao lesson = new LessonDao();
CourseBookDao courseBook = new CourseBookDao();
LmCategoryDao category = new LmCategoryDao("book");
GroupDao group = new GroupDao();

//정보
DataSet info = book.query(
	"SELECT a.*, g.category_nm category_nm, u.user_nm manager_name, l.lesson_nm "
	+ " FROM " + book.table + " a "
	+ " LEFT JOIN " + category.table + " g ON a.category_id = g.id "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " WHERE a.id = ? AND a.status != -1 AND a.site_id = ?"
,
	new Object[] {new Integer(id), new Integer(siteId)}
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("pub_date_conv", m.time("yyyy-MM-dd", info.s("pub_date")));

//변수
boolean isPackage = "P".equals(info.s("book_type"));

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("book_img"))) {
		book.item("book_img", "");
		if(!book.update("id = " + id)) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFileRoot(m.getUploadPath(info.s("book_img")));
	}
	return;
}

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리명', required:'Y'");
f.addElement("book_nm", info.s("book_nm"), "hname:'도서명', required:'Y'");
f.addElement("book_img_url", info.s("book_img_url"), "hname:'도서이미지 URL'");
f.addElement("book_img", null, "hname:'도서이미지', allow:'jpg|gif|png'");
f.addElement("book_info", info.s("book_info"), "hname:'도서정보'");
f.addElement("taxfree_yn", info.s("taxfree_yn"), "hname:'부가세면세여부', required:'Y'");
f.addElement("disc_group_yn", info.s("disc_group_yn"), "hname:'그룹할인적용여부'");
f.addElement("list_price", info.i("list_price"), "hname:'정가', option:'number'");
f.addElement("book_price", info.i("book_price"), "hname:'판매가', option:'number', required:'Y'");
f.addElement("delivery_type", info.s("delivery_type"), "hname:'배송료 타입'");
f.addElement("delivery_price", info.i("delivery_price"), "hname:'배송료', option:'number'");
f.addElement("author", info.s("author"), "hname:'저자'");
f.addElement("publisher", info.s("publisher"), "hname:'출판사'");
f.addElement("isbn", info.s("isbn"), "hname:'ISBN'");
f.addElement("pub_date", info.s("pub_date_conv"), "hname:'출간일'");
f.addElement("link", info.s("link"), "hname:'도서링크'");
f.addElement("lesson_id", info.s("lesson_id"), "hname:'e-Book'");
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'e-Book'");
f.addElement("rental_day", info.i("rental_day"), "hname:'대여일', option:'number'");
f.addElement("summary", null, "hname:'간략소개'");
f.addElement("outline", null, "hname:'도서소개', allowiframe:'Y', allowhtml:'Y'");
f.addElement("introduce", null, "hname:'저자소개', allowiframe:'Y', allowhtml:'Y'");
f.addElement("contents", null, "hname:'목차', allowiframe:'Y', allowhtml:'Y'");
f.addElement("etc1", info.s("etc1"), "hname:'기타1'");
f.addElement("etc2", info.s("etc2"), "hname:'기타2'");
f.addElement("target_yn", info.s("target_yn"), "hname:'구매대상자 사용여부', required:'Y'");
f.addElement("recomm_yn", info.s("recomm_yn"), "hname:'추천과정'");
f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("sale_yn", info.s("sale_yn"), "hname:'판매여부'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number'");

//수정
if(m.isPost() && f.validate()) {

	//제한
	if("E".equals(info.s("book_type")) && "".equals(f.get("lesson_id"))) {
		m.jsAlert("전자책을 선택해주세요.");
		return;
	}

	//제한-패키지
	if("P".equals(info.s("book_type")) && "Y".equals(f.get("display_yn")) && 0 >= bookPackage.findCount("package_id = " + id)) {
		m.jsAlert("해당 패키지에 등록된 도서가 없어 상태를 변경할 수 없습니다.");
		return;
	}

	//제한-이미지URI및용량
	String outline = f.get("outline");
	String introduce = f.get("introduce");
	String contents = f.get("contents");
	int bytesOutline = outline.replace("\r\n", "\n").getBytes("UTF-8").length;
	int bytesIntroduce = introduce.replace("\r\n", "\n").getBytes("UTF-8").length;
	int bytesContents = contents.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < outline.indexOf("<img") && -1 < outline.indexOf("data:image/") && -1 < outline.indexOf("base64")) { m.jsAlert("도서소개 이미지는 첨부파일 기능으로 업로드 해 주세요."); return; }
	if(-1 < introduce.indexOf("<img") && -1 < introduce.indexOf("data:image/") && -1 < introduce.indexOf("base64")) { m.jsAlert("저자소개 이미지는 첨부파일 기능으로 업로드 해 주세요."); return; }
	if(-1 < contents.indexOf("<img") && -1 < contents.indexOf("data:image/") && -1 < contents.indexOf("base64")) { m.jsAlert("목차 이미지는 첨부파일 기능으로 업로드 해 주세요."); return; }
	if(60000 < bytesOutline) { m.jsAlert("도서소개 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytesOutline + "바이트)"); return; }
	if(60000 < bytesIntroduce) { m.jsAlert("저자소개 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytesIntroduce + "바이트)"); return; }
	if(60000 < bytesContents) { m.jsAlert("목차 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytesContents + "바이트)"); return; }

	book.item("category_id", f.get("category_id"));
	book.item("book_nm", f.get("book_nm"));
	if(f.getFileName("book_img") != null) {
		File f1 = f.saveFile("book_img");
		if(f1 != null) {
			book.item("book_img", f.getFileName("book_img"));
			if(!"".equals(info.s("book_img"))) m.delFileRoot(m.getUploadPath(info.s("book_img")));
			
			//리사이즈
			try {
				String imgPath = dataDir + "/file/" + f1.getName();
				String cmd = "convert -resize 1000x " + imgPath + " " + imgPath;
				Runtime.getRuntime().exec(cmd);
			}
			catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); return; }
			catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); return; }
		}
	}
	book.item("book_img_url", f.get("book_img_url"));
	book.item("taxfree_yn", f.get("taxfree_yn"));
	book.item("disc_group_yn", f.get("disc_group_yn", "Y"));
	book.item("list_price", f.getInt("list_price"));
	book.item("book_price", f.getInt("book_price"));
	book.item("book_info", f.get("book_info"));
	book.item("summary", f.get("summary"));
	book.item("isbn", f.get("isbn"));
	book.item("delivery_type", f.get("delivery_type"));
	book.item("delivery_price", f.getInt("delivery_price", 0));
	book.item("author", f.get("author"));
	book.item("publisher", f.get("publisher"));
	book.item("link", f.get("link"));
	book.item("lesson_id", f.getInt("lesson_id"));
	book.item("rental_day", f.getInt("rental_day"));
	book.item("outline", outline);
	book.item("introduce", introduce);
	book.item("contents", contents);
	book.item("manager_id", f.getInt("manager_id"));
	book.item("recomm_yn", f.get("recomm_yn", "N"));
	book.item("target_yn", f.get("target_yn", "N"));
	book.item("sale_yn", f.get("sale_yn", "N"));
	book.item("display_yn", f.get("display_yn", "N"));
	book.item("pub_date", "".equals(f.get("pub_date")) ? "" : m.time("yyyyMMdd", f.get("pub_date")));
	book.item("status", f.get("status", "0"));
	book.item("etc1", f.get("etc1"));
	book.item("etc2", f.get("etc2"));

	//도서
	if(-1 != bookRelate.execute("DELETE FROM " + bookRelate.table + " WHERE book_id = " + id + "")) {
		if(null != f.getArr("relate_id")) {
			bookRelate.item("book_id", id);
			bookRelate.item("site_id", siteId);
			for(int i = 0; i < f.getArr("relate_id").length; i++) {
				bookRelate.item("relate_id", f.getArr("relate_id")[i]);
				if(!bookRelate.insert()) { }
			}
		}
	}

	//그룹
	if(-1 != bookTarget.execute("DELETE FROM " + bookTarget.table + " WHERE book_id = " + id + "")) {
		if(null != f.getArr("group_id")) {
			bookTarget.item("book_id", id);
			bookTarget.item("site_id", siteId);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				bookTarget.item("group_id", f.getArr("group_id")[i]);
				if(!bookTarget.insert()) { }
			}
		}
	}

	if(!book.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("book_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("book_type_" + info.s("book_type"), true);
info.put("book_type_conv", m.getItem(info.s("book_type"), book.packageTypes));
info.put("book_img_conv", m.encode(info.s("book_img")));
info.put("book_img_isrc", siteDomain + m.getUploadUrl(info.s("book_img")));
info.put("book_img_ek", m.encrypt(info.s("book_img") + m.time("yyyyMMdd")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

//목록-대상자
DataSet targets = bookTarget.query(
	"SELECT a.*, g.group_nm "
	+ " FROM " + bookTarget.table + " a "
	+ " INNER JOIN " + group.table + " g ON a.group_id = g.id AND g.site_id = " + siteId + " "
	+ " WHERE a.book_id = " + id + ""
);

//목록-관련책
DataSet rbooks = bookRelate.query(
	"SELECT b.id relate_id, b.book_nm relate_nm "
	+ " FROM " + bookRelate.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.relate_id = b.id "
	+ " WHERE a.book_id = " + id
);
/*
while(rbooks.next()) {
	rbooks.put("book_nm_conv", m.cutString(rbooks.s("book_nm"), 40));
	rbooks.put("status_conv", m.getItem(rbooks.s("status"), book.statusList));
	rbooks.put("display_conv", rbooks.b("display_yn") ? "정상" : "숨김");
	rbooks.put("book_type_conv", m.getItem(rbooks.s("book_type"), book.packageTypes));
	//rbooks.put("onoff_type_conv", m.getItem(rbooks.s("onoff_type"), course.onoffTypes));

	//rbooks.put("alltimes_block", "A".equals(rbooks.s("course_type")));
	//rbooks.put("request_sdate_conv", m.time("yyyy.MM.dd", rbooks.s("request_sdate")));
	//rbooks.put("request_edate_conv", m.time("yyyy.MM.dd", rbooks.s("request_edate")));
	//rbooks.put("study_sdate_conv", m.time("yyyy.MM.dd", rbooks.s("study_sdate")));
	//rbooks.put("study_edate_conv", m.time("yyyy.MM.dd", rbooks.s("study_edate")));
}
*/

//출력
p.setBody("book.book_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("targets", targets);
p.setLoop("rbooks", rbooks);

p.setLoop("types", m.arr2loop(book.types));
p.setLoop("status_list", m.arr2loop(book.statusList));
p.setLoop("taxfree_yn", m.arr2loop(book.taxfreeYn));
p.setLoop("display_yn", m.arr2loop(book.displayYn));
p.setLoop("delivery_types", m.arr2loop(book.deliveryTypes));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("courses", courseBook.getCourses(id));
p.setLoop("categories", category.getList(siteId));

p.setVar("tab_modify", "current");
p.setVar("package_block", isPackage);
p.setVar("course_cnt", courseBook.getCourseCount(id));
p.display();

%>