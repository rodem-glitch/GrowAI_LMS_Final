<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BookDao book = new BookDao();
LmCategoryDao category = new LmCategoryDao("book");

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_category", null, null);
//f.addElement("s_book_type", null, null);
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_status", null, null);

f.addElement("s_subject", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	book.table + " a "
);
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.category_id", f.get("s_category"));
//lm.addSearch("a.book_type", f.get("s_book_type"));
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", m.rs("s_sdate")), ">=");
lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", m.rs("s_edate")), "<=");
if(!"".equals(m.rs("s_field"))) lm.addSearch(m.rs("s_field"), f.get("s_keyword").replace("`", "\'"), "LIKE");
else if("".equals(m.rs("s_field")) && !"".equals(m.rs("s_keyword"))) lm.addSearch("a.book_nm,a.author,a.publisher", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 100));
	list.put("link", !"".equals(list.s("link")) ? "http://" + m.replace(list.s("link"), "http://", "") : "");
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
	list.put("status_conv", m.getItem(list.s("status"), book.statusList));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("price_conv", m.nf(list.i("book_price")));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("package_block", "P".equals(list.s("book_type")));
	list.put("ebook_block", "E".equals(list.s("book_type")));
	list.put("book_type_conv", m.getItem(list.s("book_type"), book.packageTypes));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "도서관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "book_nm=>도서명", "book_img=>이미지", "price_conv=>가격", "author=>저작자", "publisher=>출판사", "link=>링크", "outline=>도서내용", "reg_date_conv=>등록일", "status_conv=>상태" }, "도서관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("book.book_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("categories", categories);
p.setLoop("status_list", m.arr2loop(book.statusList));
p.setLoop("types", m.arr2loop(book.types));
p.display();

%>