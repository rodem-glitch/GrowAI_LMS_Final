<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(122, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "category";
String cid = m.rs("cid");

//객체
LmCategoryDao category = new LmCategoryDao("webtv");

//목록
DataSet list = category.getList(siteId);
//DataSet list = category.find("status = 1 AND module = 'webtv' AND site_id = " + siteId + "", "*", "parent_id ASC, sort ASC");
//m.p(list);

//엑셀
if("excel".equals(m.rs("mode"))) {
    ExcelWriter ex = new ExcelWriter(response, "방송카테고리(" + m.time("yyyy-MM-dd") + ").xls");
    ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "depth=>단계", "sort=>순서", "category_nm=>카테고리명", "name_conv=>카테고리경로", "parent_id=>상위카테고리ID", "list_type=>목록형태", "sort_type=>정렬순서", "list_num=>목록갯수", "display_yn=>노출여부", "target_yn=>시청대상여부", "login_yn=>회원전용여부", "hit_cycle=>조회수갱신주기", "status=>상태" }, "방송카테고리(" + m.time("yyyy-MM-dd") + ")");
    ex.write();
    return;
}

//출력
p.setLayout("blank");
p.setBody("webtv.category_tree");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.setVar(mode + "_block", true);
p.setVar("cid", cid);
p.display();

%>