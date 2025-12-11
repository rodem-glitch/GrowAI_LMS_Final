<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String mode = m.rs("mode");
if("".equals(mode)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookDao book = new BookDao();
LmCategoryDao category = new LmCategoryDao("book");

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(book.table + " a ");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
if(!"relate".equals(mode) && !"main".equals(mode)) lm.addWhere("a.book_type = 'R'");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", f.get("s_edate")), "<=");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.book_nm, a.author, a.publisher", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//카테고리
DataSet categories = category.getList(siteId);

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
}

//출력
p.setLayout("pop");
p.setBody("book.book_select");
p.setVar("p_title", "도서 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar(m.rs("mode") + "_block", true);
p.display();

%>