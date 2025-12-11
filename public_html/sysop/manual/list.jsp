<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ManualDao manual = new ManualDao();

//목록
DataSet list = manual.find("status = 1", "*", "depth ASC, sort ASC");;
while(list.next()) {
	list.put("parent_id", "".equals(list.s("parent_id")) ? "-" : list.s("parent_id"));
	list.put("status_conv", m.getItem(list.s("status"), manual.statusList));
	list.put("display_block", list.i("status") == 1);
}

//출력
p.setLayout("blank");
p.setBody("manual.list");
p.setVar("p_title", "매뉴얼");

p.setLoop("list", list);
p.display();

%>