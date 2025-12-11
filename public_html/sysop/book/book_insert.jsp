<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
boolean isPackage = "package".equals(m.rs("mode"));

//객체
BookDao book = new BookDao();
BookTargetDao bookTarget = new BookTargetDao();
LmCategoryDao category = new LmCategoryDao("book");
GroupDao group = new GroupDao();

//목록-카테고리
DataSet categories = category.getList(siteId);
if(1 > categories.size()) { m.jsError("등록된 도서카테고리가 없습니다.\\n도서를 등록하시려면 먼저 도서카테고리를 등록해주세요."); return; }

//폼체크
f.addElement("book_type", isPackage ? "P" : "R", "hname:'도서 구분', required:'Y'");
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
//f.addElement("category_nm", null, "hname:'카테고리', required:'Y'");
f.addElement("book_nm", null, "hname:'도서명', required:'Y'");
f.addElement("book_img_url", null, "hname:'도서이미지 URL'");
f.addElement("book_img", null, "hname:'도서이미지', allow:'jpg|gif|png'");
f.addElement("book_info", null, "hname:'도서정보'");
f.addElement("taxfree_yn", "Y", "hname:'부가세면세여부', required:'Y'");
f.addElement("disc_group_yn", "Y", "hname:'그룹할인적용여부'");
f.addElement("list_price", 0, "hname:'정가', option:'number'");
f.addElement("book_price", 0, "hname:'판매가', option:'number', required:'Y'");
f.addElement("delivery_type", "A", "hname:'배송료 타입'");
f.addElement("delivery_price", 0, "hname:'배송료', option:'number'");
f.addElement("author", null, "hname:'저자'");
f.addElement("publisher", null, "hname:'출판사'");
f.addElement("isbn", null, "hname:'ISBN'");
f.addElement("pub_date", null, "hname:'출간일'");
f.addElement("link", null, "hname:'미리보기 링크'");
f.addElement("lesson_id", null, "hname:'e-Book'");
f.addElement("rental_day", 0, "hname:'대여일', option:'number'");
f.addElement("summary", null, "hname:'간략소개'");
f.addElement("outline", null, "hname:'도서소개', allowiframe:'Y', allowhtml:'Y'");
f.addElement("introduce", null, "hname:'저자소개', allowiframe:'Y', allowhtml:'Y'");
f.addElement("contents", null, "hname:'목차', allowiframe:'Y', allowhtml:'Y'");
f.addElement("etc1", null, "hname:'기타1'");
f.addElement("etc2", null, "hname:'기타2'");
//f.addElement("target_yn", "N", "hname:'학습대상자 사용여부', required:'Y'");
f.addElement("recomm_yn", null, "hname:'추천과정'");
f.addElement("sale_yn", "Y", "hname:'판매여부'");
f.addElement("display_yn", "Y", "hname:'노출여부'");
f.addElement("status", 1, "hname:'상태'");

//등록
if(m.isPost() && f.validate()) {
	//제한
	if("E".equals(f.get("book_type")) && "".equals(f.get("lesson_id"))) {
		m.jsAlert("전자책을 선택해주세요.");
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

	int newId = book.getSequence();

	book.item("id", newId);
	book.item("site_id", siteId);
	book.item("category_id", f.get("category_id"));
	book.item("book_type", f.get("book_type"));
	book.item("book_nm", f.get("book_nm"));
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
	book.item("link", !"".equals(f.get("link")) ? "http://" + m.replace(f.get("link"), "http://", "") : "");
	book.item("lesson_id", f.getInt("lesson_id"));
	book.item("rental_day", f.getInt("rental_day"));
	book.item("outline", outline);
	book.item("introduce", introduce);
	book.item("contents", contents);
	book.item("manager_id", userId);
	book.item("recomm_yn", f.get("recomm_yn", "N"));
	book.item("target_yn", f.get("target_yn", "N"));
	book.item("sale_yn", f.get("sale_yn", "N"));
	book.item("display_yn", f.get("display_yn", "N"));
	book.item("pub_date", "".equals(f.get("pub_date")) ? "" : m.time("yyyyMMdd", f.get("pub_date")));
	book.item("reg_date", m.time("yyyyMMddHHmmss"));
	book.item("status", f.get("status", "0"));
	book.item("etc1", f.get("etc1"));
	book.item("etc2", f.get("etc2"));

	if(f.getFileName("book_img") != null) {
		File f1 = f.saveFile("book_img");
		if(f1 != null) { book.item("book_img", f.getFileName("book_img")); }
		
		//리사이즈
		try {
			String imgPath = dataDir + "/file/" + f1.getName();
			String cmd = "convert -resize 1000x " + imgPath + " " + imgPath;
			Runtime.getRuntime().exec(cmd);
		}
		catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); return; }
		catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); return; }
	}

	if(!book.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("book_list.jsp", "parent");
	return;
}

//출력
p.setBody("book.book_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("form_script", f.getScript());

p.setLoop("types", m.arr2loop(book.types));
p.setLoop("status_list", m.arr2loop(book.statusList));
p.setLoop("taxfree_yn", m.arr2loop(book.taxfreeYn));
p.setLoop("display_yn", m.arr2loop(book.displayYn));
p.setLoop("delivery_types", m.arr2loop(book.deliveryTypes));
p.setLoop("categories", categories);

p.setVar("package_block", isPackage);
p.display();

%>