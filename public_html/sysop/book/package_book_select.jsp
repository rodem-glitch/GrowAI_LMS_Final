<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if("".equals(id)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookDao book = new BookDao();
BookPackageDao bookPackage = new BookPackageDao();
LmCategoryDao category = new LmCategoryDao("book");

//정보
DataSet pinfo = book.find("id = " + id + " AND book_type = 'P' AND status != -1 AND site_id = " + siteId + "");
if(!pinfo.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//등록
if(m.isPost() && f.validate()) {

	String[] idx = f.getArr("bidx");
	int failed = 0;
	if(idx != null) {
		int maxSort = bookPackage.getLastSort(id);

		bookPackage.item("package_id", id);
		bookPackage.item("site_id", siteId);

		DataSet items = book.query(
			"SELECT a.* "
			+ " FROM " + book.table + " a "
			+ " WHERE a.book_type != 'P' AND a.status = 1 AND a.site_id = " + siteId + " "
			+ " AND a.id IN (" + m.join(",", idx) + ") "
			+ " AND NOT EXISTS ( "
				+ " SELECT 1 FROM " + bookPackage.table + " WHERE package_id = " + id + " AND book_id = a.id "
			+ " ) "
		);
		while(items.next()) {
			bookPackage.item("book_id", items.s("id"));
			bookPackage.item("sort", ++maxSort);
			if(!bookPackage.insert()) { failed++; }
		}
	}

	//갱신
	bookPackage.autoSort(id);

	if(0 < failed) { m.jsAlert(failed + "개의 과정 등록에 실패했습니다."); }
	else { m.jsAlert("성공적으로 추가했습니다."); }
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_book_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(book.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.id != " + m.ri("id") + "");
lm.addWhere("a.id NOT IN (" + m.ri("idx") + ")");
lm.addWhere("a.book_type = 'E'");
//lm.addWhere("a.book_type != 'P'");
//lm.addSearch("a.book_type", f.get("s_book_type"));
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.book_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");


//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 50));
	list.put("status_conv", m.getItem(list.s("status"), book.statusList));
	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("book_file_url", !"".equals(list.s("book_file")) ? siteDomain + m.getUploadUrl(list.s("book_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("book_type_conv", m.getItem(list.s("book_type"), book.types));
}

//출력
p.setLayout("pop");
p.setVar("p_title", "도서선택");
p.setBody("book.package_book_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(book.statusList));
p.setLoop("categories", categories);
p.setLoop("types", m.arr2loop(book.types));

p.display();

%>