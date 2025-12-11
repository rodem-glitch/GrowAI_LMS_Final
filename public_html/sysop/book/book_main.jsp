<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(110, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String type = m.rs("type", "recomm");
String mode = m.rs("mode");

f.addElement("type", type, null);


//객체
BookDao book = new BookDao();
LmCategoryDao category = new LmCategoryDao("book");
MCal mcal = new MCal(); mcal.yearRange = 10;
BookMainDao bm = new BookMainDao();


if("add".equals(mode)) {

	if(0 == bm.findCount("site_id = " + siteId + " AND type = '" + type + "' AND book_id = " + m.ri("cid"))) {
		bm.item("site_id", siteId);
		bm.item("type", type);
		bm.item("book_id", m.ri("cid"));
		bm.item("sort", bm.getLastSort(siteId, type));
		bm.insert();
	}

	m.redirect("book_main.jsp?type=" + type);
	return;

} else if("del".equals(mode)) {

	bm.delete("site_id = " + siteId + " AND type = '" + type + "' AND book_id = " + m.ri("id"));
	m.redirect("book_main.jsp?type=" + type);
	return;

} else if("sort".equals(mode)) {

	String[] idx = m.reqArr("idx");
	if(null != idx) {
		for(int i=0; i<idx.length; i++) {
			bm.item("sort", i);
			bm.update("site_id = " + siteId + " AND type = '" + type + "' AND book_id = " + idx[i]);
		}
	}
	m.redirect("book_main.jsp?type=" + type);
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	bm.table + " m "
	+ " JOIN " + book.table + " a ON a.id = m.book_id"
);
lm.setFields("a.*, m.sort");
lm.addWhere("a.status != -1");
lm.addWhere("m.site_id = " + siteId + " AND m.type = '" + type + "'");
lm.setOrderBy("m.sort ASC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), book.statusList));
	list.put("display_conv", list.b("display_yn") ? "정상" : "숨김");

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("pub_date_conv", m.time("yyyy.MM.dd", list.s("pub_date")));
}

//출력
p.setBody("book.book_main");
p.setLoop("list", list);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("type", type);
p.setVar("form_script", f.getScript());
p.display();

%>
