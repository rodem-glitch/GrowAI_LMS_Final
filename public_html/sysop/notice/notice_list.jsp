<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//객체
NoticeDao notice = new NoticeDao();

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(notice.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addSearch("category", f.get("s_category"));
lm.addSearch("status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.subject,a.content", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("category_conv", m.getItem(list.s("category"), notice.categories));
	list.put("subject_conv", m.cutString(list.s("subject"), 100));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("hit_conv", m.nf(list.i("hit_cnt")));
	list.put("status_conv", m.getItem(list.s("status"), notice.statusList));
}

//출력
p.setLayout(ch);
p.setBody("notice.notice_list");
p.setVar("p_title", "서비스 공지사항");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(notice.statusList));
p.setLoop("categories", m.arr2loop(notice.categories));
p.display();

%>