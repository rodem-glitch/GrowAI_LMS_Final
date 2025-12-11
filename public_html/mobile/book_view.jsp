<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
LmCategoryDao category = new LmCategoryDao("book");
BookDao book = new BookDao();
BookTargetDao bookTarget = new BookTargetDao();
BookPackageDao bookPackage = new BookPackageDao();
BookRelateDao bookRelate = new BookRelateDao();
CourseBookDao courseBook = new CourseBookDao();
CourseDao course = new CourseDao();

//정보
DataSet info = book.query(
	"SELECT a.* "
	+ " FROM " + book.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 AND c.module = 'book' "
	//+ " WHERE a.id = " + id + " AND a.site_id = "+ siteId +" AND a.status = 1 AND a.display_yn = 'Y' "
	+ " WHERE a.id = " + id + " AND a.site_id = "+ siteId +" AND a.status = 1 "
	+ " AND (a.target_yn = 'N'" + (
			!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + bookTarget.table + " WHERE book_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
	+ ") "
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

if(!"".equals(info.s("book_img"))) info.put("book_img_url", m.getUploadUrl(info.s("book_img")));
info.put("pub_date_conv", m.time(_message.get("format.datetime.local"), info.s("pub_date")));

info.put("price_conv", m.nf(info.i("book_price")) + "원");

info.put("list_price_conv", m.nf(info.i("list_price")) + "원");
info.put("list_price_block", info.i("list_price") > 0);

info.put("free_block", info.i("book_price") == 0);

info.put("delivery_price_conv",
	"A".equals(info.s("delivery_type"))
	? "착불"
	: (info.i("delivery_price") > 0 ? m.nf(info.i("delivery_price")) + "원" : "무료")
);

//목록-사용강좌
DataSet courses = courseBook.getCourses(id);
while(courses.next()) {
	courses.put("study_sdate_conv", m.time(_message.get("format.date.dot"), courses.s("study_sdate")));
	courses.put("study_edate_conv", m.time(_message.get("format.date.dot"), courses.s("study_edate")));
	courses.put("request_date", "-");
	if("R".equals(courses.s("course_type"))) {
		courses.put("request_date", m.time(_message.get("format.date.dot"), courses.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), courses.s("request_edate")));
		courses.put("study_date", m.time(_message.get("format.date.dot"), courses.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), courses.s("study_edate")));
		courses.put("ready_block", 0 > m.diffDate("D", courses.s("request_sdate"), m.time("yyyyMMdd")));
	} else if("A".equals(courses.s("course_type"))) {
		courses.put("request_date", "상시");
	}
	courses.put("course_nm_conv", m.cutString(courses.s("course_nm"), 64));
	courses.put("price_conv", courses.i("price") > 0 ? m.nf(courses.i("price")) + "원" : "무료");
}

//목록-관련책
DataSet rbooks = bookRelate.query(
	"SELECT b.* "
	+ " FROM " + bookRelate.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.relate_id = b.id "
	+ " WHERE a.book_id = " + id
	+ " AND (b.target_yn = 'N'" + (
			!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + bookTarget.table + " WHERE book_id = b.id AND group_id IN (" + userGroups + "))"
			: "")
	+ ") "
);
while(rbooks.next()) {
	rbooks.put("book_nm_conv", m.cutString(rbooks.s("book_nm"), 40));
	rbooks.put("book_type_conv", m.getItem(rbooks.s("book_type"), book.types));

	if(!"".equals(rbooks.s("book_img"))) rbooks.put("book_img_url", m.getUploadUrl(rbooks.s("book_img")));
	rbooks.put("pub_date_conv", m.time(_message.get("format.datetime.local"), rbooks.s("pub_date")));

	rbooks.put("price_conv", m.nf(rbooks.i("book_price")) + "원");

	rbooks.put("list_price_conv", m.nf(rbooks.i("list_price")) + "원");
	rbooks.put("list_price_block", rbooks.i("list_price") > 0);

	rbooks.put("free_block", rbooks.i("book_price") == 0);

	rbooks.put("delivery_price_conv",
		"A".equals(rbooks.s("delivery_type"))
		? "착불"
		: (rbooks.i("delivery_price") > 0 ? m.nf(rbooks.i("delivery_price")) + "원" : "무료")
	);
}

//패키지에포함된책
DataSet books = bookPackage.query(
	"SELECT a.*, b.* "
	+ " FROM " + bookPackage.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id AND b.site_id = " + siteId + " AND b.book_type != 'P' AND b.status = 1 "
	+ " WHERE a.package_id = " + id + " "
	+ " ORDER BY a.sort ASC"
);
while(books.next()) {
	books.put("book_nm_conv", m.cutString(books.s("book_nm"), 40));
	books.put("book_type_conv", m.getItem(books.s("book_type"), book.types));
	books.put("price_conv", m.nf(books.i("book_price")) + "원");
	books.put("list_price_conv", m.nf(books.i("list_price")) + "원");
	books.put("list_price_block", books.i("list_price") > 0);
	books.put("free_block", books.i("book_price") == 0);
}

//책이포함된패키지
DataSet packages = bookPackage.query(
	"SELECT a.*, b.* "
	+ " FROM " + bookPackage.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.package_id = b.id AND b.site_id = " + siteId + " AND b.book_type = 'P' AND b.display_yn = 'Y' AND b.status = 1 "
	+ " WHERE a.book_id = " + id + " "
	+ " ORDER BY a.sort ASC"
);
while(packages.next()) {
	packages.put("book_nm_conv", m.cutString(packages.s("book_nm"), 40));
}

//출력
p.setLayout(ch);
p.setBody("mobile.book_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("buy_block", info.i("price") > 0);
p.setVar("ebook_block", !"R".equals(info.s("book_type")));
p.setVar("real_block", "R".equals(info.s("book_type")));
p.setVar("package_block", "P".equals(info.s("book_type")));
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.setLoop("courses", courses);
p.setLoop("books", books);
p.setLoop("rbooks", rbooks);
p.display();

%>