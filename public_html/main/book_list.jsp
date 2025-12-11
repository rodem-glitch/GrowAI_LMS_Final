<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String type = m.rs("type", "recomm");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;

String today = m.time("yyyyMMdd");

//객체
BookDao book = new BookDao();
BookMainDao bm = new BookMainDao();

//목록
//book.d(out);
DataSet list = book.query(
	"SELECT a.*"
	+ " FROM " + bm.table + " m INNER JOIN " + book.table + " a ON a.id = m.book_id "
	+ " WHERE a.status = 1 AND m.site_id = " + siteId + " AND m.type = '" + type + "'"
	+ " ORDER BY m.sort ASC "
	, count
);
while(list.next()) {
	list.put("pub_date_conv", m.time(_message.get("format.date.dot"), list.s("pub_date")));
	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 14));
	list.put("book_info_conv", m.cutString(m.stripTags(list.s("book_info")), 120));
	list.put("book_price_conv", list.i("book_price") > 0 ? m.nf(list.i("book_price")) + "원" : "무료");
	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
}

//출력
p.setLayout(null);
if(new File(tplRoot + "/main/book_" + type + "_list.html").exists()) {
	p.setBody("main.book_" + type + "_list");
} else {
	p.setBody("main.book_list");
}
p.setLoop("list", list);
p.setVar("arrow_block", 1 < list.size());
p.setVar("type_" + type, true);
p.display();

%>