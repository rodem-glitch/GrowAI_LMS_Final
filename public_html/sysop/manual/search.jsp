<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼체크
f.addElement("s_keyword", null, null);

//객체
ManualDao manual = new ManualDao();

//목록
DataSet list = new DataSet();
if(!"".equals(f.get("s_keyword"))) {

	String keyword = m.rs("s_keyword");
	list = manual.find(
		"status = 1 "
		+ " AND ( "
			+ " manual_nm LIKE '%" + keyword + "%' "
			+ "OR tag LIKE '%" + keyword + "%' "
			+ "OR description LIKE '%" + keyword + "%' "
		+ " ) "
		, "*", "depth ASC, sort ASC"
	);
	while(list.next()) {

	}
}

//출력
p.setLayout("blank");
p.setBody("manual.search");
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.display();

%>