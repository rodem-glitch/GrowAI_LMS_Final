<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LmCategoryDao category = new LmCategoryDao("book");
BookDao book = new BookDao();
BookTargetDao bookTarget = new BookTargetDao();

//변수
String today = m.time("yyyyMMdd");

//폼입력
String style = "webzine";
String ord = m.rs("ord");
int categoryId = m.ri("cid", -1000000 - siteId);
int listNum = 10;

//카테고리가 지정될 경우 카테고리 정보 가져옴.
String pTitle = "전체도서";
DataSet cateInfo = category.find("id = " + categoryId + "");
if(cateInfo.next()) {
	if(categoryId > 0) pTitle = cateInfo.s("category_nm");
	if(!"".equals(cateInfo.s("list_type"))) style = cateInfo.s("list_type");
	if("".equals(ord) && !"".equals(cateInfo.s("sort_type"))) ord = cateInfo.s("sort_type");
	if(cateInfo.i("list_num") > 0) listNum = cateInfo.i("list_num");
}
if(categoryId > 0) {
	//p.setLoop("categories", category.getSubList(siteId, categoryId));
	p.setLoop("sub_categories", category.getSubList(siteId, categoryId));
} else if("st asc".equals(ord)) {
	ord = "as asc";
}

if(!"".equals(m.rs("s_style"))) style = m.rs("s_style");
ord = m.getItem(ord.toLowerCase(), book.ordList);

//폼체크
f.addElement("s_style", style, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("scid", null, null);
f.addElement("ord", null, null);
f.addElement("cid", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(listNum);
lm.setNaviNum(5);
lm.setTable(book.table + " a");
lm.setFields("a.*");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.status = 1");
lm.addWhere("a.display_yn = 'Y'");
//특정 카테고리가 지정된 경우 하위카테고리 포함 도서 검색
if(categoryId > 0) {
	String subIdx = category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : categoryId);
	lm.addWhere("a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ")");
}
//학습그룹이 지정된 경우 검색 조건 추가
lm.addWhere(
	"(a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + bookTarget.table + " WHERE book_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
);

String sField = f.get("s_field", "");
String allowFields = "a.book_nm,a.outline";
if(!m.inArray(sField, allowFields)) sField = "";
if(!"".equals(sField)) lm.addSearch(sField, f.get("s_keyword"), "LIKE");
else lm.addSearch(allowFields, f.get("s_keyword"), "LIKE");

//정렬기준에 따라
lm.setOrderBy(!"".equals(ord) ? ord : "a.id DESC");
DataSet list = lm.getDataSet();

//포맷팅
while(list.next()) {

	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 40));
	list.put("book_nm_gallery", m.cutString(list.s("book_nm"), 20));
	//list.put("book_info_conv", m.cutString(m.stripTags(list.s("book_info")), 220));

	if(!"".equals(list.s("summary"))) {
		list.put("summary_conv", m.cutString(m.nl2br(list.s("summary")), 170));
	} else {
		list.put("summary_conv", m.cutString(m.stripTags(list.s("outline")), 170));
	}
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));

	list.put("price_conv", list.i("book_price") > 0 ? siteinfo.s("currency_prefix") + m.nf(list.i("book_price")) + siteinfo.s("currency_suffix") : _message.get("payment.unit.free"));
	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);
	list.put("pub_date_conv", "".equals(list.s("pub_date")) ? "" : m.time(_message.get("format.date.dot"), list.s("pub_date")));
	list.put("ebook_block", !"R".equals(list.s("book_type")));
	list.put("package_block", "P".equals(list.s("book_type")));
}

//출력
p.setLayout(ch);
p.setBody("mobile.book_list");
p.setVar("p_title", pTitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,cid"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_type", "list".equals(style));
p.setVar("webzine_type", "webzine".equals(style));
p.setVar("gallery_type", "gallery".equals(style));

p.setVar("category", cateInfo);
//p.setLoop("categories", category.getSubList(siteId, categoryId, 0));
p.setLoop("categories", category.getList(siteId, 0, "display_yn = 'Y'"));

p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.setVar("style", style);
p.display();

%>