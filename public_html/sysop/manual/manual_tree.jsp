<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ManualDao manual = new ManualDao();

//목록
DataSet list = manual.getList();
while(list.next()) {
	list.put("parent_id", "".equals(list.s("parent_id")) ? "-" : list.s("parent_id"));
	list.put("status_conv", m.getItem(list.s("status"), manual.statusList));
	list.put("display_block", list.i("status") == 1);
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "매뉴얼관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "id=>아이디", "manual_nm=>매뉴얼명", "manual_file=>매뉴얼파일", "manual_video=>매뉴얼동영상", "depth=>DEPTH", "sort=>순서", "status_conv=>상태" }, "매뉴얼관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout("blank");
p.setBody("manual.manual_tree");
p.setVar("p_title", "매뉴얼");

p.setLoop("list", list);
p.display();

%>