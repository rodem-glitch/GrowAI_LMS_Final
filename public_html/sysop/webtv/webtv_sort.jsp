<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

int cid = m.ri("cid");

//객체
WebtvDao webtv = new WebtvDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("webtv");

//변수
boolean isTop = cid == 0;

//처리
if(m.isPost()) {
	String idx[] = m.reqArr("id");
	String sorts[] = m.reqArr("sort");

	if(idx == null || sorts == null) {
		m.jsError("순서를 정렬할 방송이 없습니다.");
		return;
	}

	for(int i = 0; i < idx.length; i++) {
		webtv.item((isTop ? "allsort" : "sort"), sorts[i]);
		webtv.update("id = " + idx[i] + " AND site_id = " + siteId);
	}

	m.redirect("webtv_sort.jsp?cid=" + cid);
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListMode(0);
lm.setListNum(1000);
lm.setTable(webtv.table + " a LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.module = 'webtv'");
lm.setFields("a.id, a.category_id, a.webtv_nm, a.display_yn, a.status, a.sort, a.allsort, c.category_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
if(!isTop) lm.addWhere("a.category_id IN (" + category.getSubIdx(siteId, cid) + ")");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : (isTop ? "a.allsort, a.id DESC" : "a.sort, a.id DESC"));

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("category_nm_conv", category.getTreeNames(list.i("category_id")));
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 50));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), webtv.displayList));
	list.put("status_conv", m.getItem(list.s("status"), webtv.statusList));
}

//m.p(list);
//출력
p.setLayout("pop");
p.setBody("webtv.webtv_sort");
p.setVar("p_title", "정렬순서지정");
p.setLoop("list", list);
p.setVar("top", isTop);
p.display();

%>