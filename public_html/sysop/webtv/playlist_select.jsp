<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int tid = m.ri("tid");
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "move";

//객체
LmCategoryDao category = new LmCategoryDao("webtv_playlist");

//목록
DataSet list = category.query(
	" SELECT a.*, b.cnt "
	+ " FROM " + category.table + " a "
	+ " LEFT JOIN ( "
		+ " SELECT parent_id, COUNT(*) cnt FROM " + category.table + " WHERE status = 1 AND module = 'webtv_playlist' GROUP BY parent_id "
	+ " ) b ON a.id = b.parent_id "
	+ " WHERE a.status = 1 AND module = 'webtv_playlist' AND a.site_id = " + siteId + " "
	+ " ORDER BY a.parent_id ASC, a.sort ASC "
);
category.setData(list);
String[] arr = tid != 0 ? category.getChildNodes(""+tid) : null;
list.first();
while(list.next()) {
	list.put("cnt", list.i("cnt") + 1);
	list.put("is_child", m.inArray(list.s("id"), arr));
}

//출력
p.setLayout("pop");
p.setBody("webtv.playlist_select");
p.setVar("p_title", "플레이리스트 선택");
p.setLoop("list", list);

p.setVar(mode + "_block", true);
p.setVar("root_cnt", category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'webtv_playlist' AND depth = 1") + 1);
p.display();

%>