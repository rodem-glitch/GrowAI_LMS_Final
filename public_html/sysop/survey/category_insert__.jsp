<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(35, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SurveyCategoryDao category = new SurveyCategoryDao();

//폼체크
f.addElement("category_nm", null, "hname:'카테고리명', required:'Y'");

if(m.isPost() && !"".equals(m.rs("category_nm"))) {
	category.item("site_id", siteinfo.i("id"));
	category.item("category_nm", f.get("category_nm"));
	category.item("use_cnt", 0);
	category.item("reg_date", m.time("yyyyMMddHHmmss"));
	category.item("status", 1);

	if(!category.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("pop_category.jsp?" + m.qs(), "parent");
	return;
}

%>