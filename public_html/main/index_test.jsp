<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

DataSet list = new DataSet();
list.addRow();
list.put("type", "banner");
list.put("title", "메인 배너");
list.put("width", 8);
list.put("height", 300);
list.put("params", null);
list.put("param1", "main");
list.put("param2", 4);

list.addRow();
list.put("type", "course_main");
list.put("title", "신규강의");
list.put("width", 6);
list.put("height", 200);
list.put("params", null);
list.put("param1", "new");
list.put("param2", 2);

list.addRow();
list.put("type", "course_main");
list.put("title", "베스트강의");
list.put("width", 6);
list.put("height", 200);
list.put("params", null);
list.put("param1", "best");
list.put("param2", 2);

list.addRow();
DataSet params = new DataSet();
params.addRow();
params.put("__first", true);
params.put("data1", "카테고리auto1");
params.put("data2", "etc1");
params.put("data3", 4);
params.addRow();
params.put("__first", false);
params.put("data1", "카테고리auto2");
params.put("data2", "etc2");
params.put("data3", 4);
params.addRow();
params.put("__first", false);
params.put("data1", "카테고리auto3");
params.put("data2", "etc3");
params.put("data3", 4);
params.addRow();
params.put("__first", false);
params.put("data1", "카테고리auto4");
params.put("data2", "etc4");
params.put("data3", 4);
list.put("type", "course_recomm");
list.put("title", "추천강의");
list.put("width", 6);
list.put("height", 200);
list.put(".params", params);

list.addRow();
list.put("type", "tutor");
list.put("title", "강사소개");
list.put("width", 12);
list.put("height", 200);
list.put("params", null);
list.put("param1", 4);

list.addRow();
list.put("type", "review");
list.put("title", "수강후기<br>BEST 5");
list.put("width", 12);
list.put("height", 200);
list.put("params", null);
list.put("param1", 5);
list.put("param2", 100);

list.first();

//포맷팅
int colMax = 12;
int colCount = colMax;
while(list.next()) {
	colCount += list.i("width");
	if(colCount > colMax) {
		colCount = list.i("width");
		list.put("row_block", true);
	} else {
		list.put("row_block", false);
	}
}
m.p(list.toString());

//출력
p.setDebug(out);
p.setLayout(ch);
p.setBody(ch + ".index_test");

p.setLoop("list", list);
p.display();

%>