<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookDao book = new BookDao();
BookPackageDao bookPackage = new BookPackageDao();
LmCategoryDao category = new LmCategoryDao("book");

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet info = book.find("id = " + id + " AND book_type = 'P' AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("cate_name", category.getTreeNames(info.i("category_id")));
info.put("status_conv", m.getItem(info.s("status"), book.statusList));
info.put("display_conv", info.b("display_yn") ? "정상" : "숨김");

if("del".equals(m.rs("mode"))) {
	//삭제
	if("".equals(f.get("idx"))) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	if(-1 == bookPackage.execute(
			"DELETE FROM " + bookPackage.table + " "
			+ " WHERE package_id = " + id + " AND book_id IN (" + f.get("idx") + ")")
	) {
		m.jsError("도서를 삭제하는 중 오류가 발생했습니다.");
		return;
	};

	bookPackage.autoSort(id);

	//제한
	if(info.b("display_yn") && 0 >= bookPackage.findCount("package_id = " + id)) {
		book.item("display_yn", "N");
		if(!book.update("id = " + id + " AND book_type = 'P' AND status != -1 AND site_id = " + siteId + "")) {
			m.jsError("패키지를 수정하는 중 오류가 발생했습니다.");
			return;
		}
		m.jsAlert("해당 패키지에 등록된 도서가 없어 패키지가 숨김 상태로 변경되었습니다.");
	}

	//이동
	m.jsReplace("package_book.jsp?" + m.qs("mode, idx"));
	return;
}

//수정
if(m.isPost() && f.validate()) {
	if(f.getArr("book_id") != null) {
		int sort = 0;
		for(int i = 0; i < f.getArr("book_id").length; i++) {
			bookPackage.item("sort", ++sort);
			if(!bookPackage.update("package_id = " + id + " AND book_id = " + f.getArr("book_id")[i])) { }
		}
	}

	m.jsAlert("수정되었습니다.");
	m.jsReplace("package_book.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000);
lm.setTable(
	bookPackage.table + " a "
	+ " INNER JOIN " + book.table + " b ON "
		+ " a.book_id = b.id "
);
lm.setFields("b.*, a.*");
lm.addWhere("a.package_id = " + id + "");
lm.setOrderBy("a.sort ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {

	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 100));
	list.put("status_conv", m.getItem(list.s("status"), book.statusList));
	list.put("display_conv", list.b("display_yn") ? "정상" : "숨김");

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("book_file_url", !"".equals(list.s("book_file")) ? siteDomain + m.getUploadUrl(list.s("book_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("book_type_conv", m.getItem(list.s("book_type"), book.types));

	list.put("curr_sort", list.i("sort") * 1000);
}

//출력
p.setBody("book.package_book");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar(info);

p.setVar("tab_book", "current");
p.display();

%>