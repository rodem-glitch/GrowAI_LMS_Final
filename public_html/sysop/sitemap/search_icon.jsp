<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(125, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//파일 목록
DataSet list = new DataSet();
File file = new File(docRoot + "/sysop/html/images/admin/icon");

//아이콘 파일 존재여부 검사
if(file.exists()) {
	try {
		File[] images = file.listFiles();
		Arrays.sort(images);
		for (int i = 0; i < images.length; i++) {
			list.addRow();
			list.put("url", "../html/images/admin/icon/" + images[i].getName());
			list.put("tr", (i + 1) % 10 == 0 && (i + 1) != images.length ? "</tr><tr height='22'>" : "");
		}
	} catch (NullPointerException npe) {
		m.errorLog("NullPointerException : " + npe.getMessage(), npe);
	}
}

//공백 출력 td
int max = list.size();
DataSet xTd = new DataSet();
if(max % 10 != 0) {
	for(int i=10; i > max % 10; i--) {
		xTd.addRow();
		xTd.put("td", "&nbsp;");
	}
}

//페이지 출력
p.setLayout("blank");
p.setBody("menu.search_icon");
p.setLoop("list", list);
p.setLoop("x_td", xTd);
p.display(out);

%>