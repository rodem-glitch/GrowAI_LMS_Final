<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
PopupDao popup = new PopupDao();

//목록
DataSet list = popup.find("popup_type = 'mobile' AND site_id = " + siteId + " AND status = 1 AND '" + m.time("yyyyMMdd") + "' BETWEEN start_date AND end_date", "*", "id DESC");

//정보
DataSet info = new DataSet();

//포맷팅
while(list.next()) {
	if(!"done".equals(m.getCookie("POPUP_MOBILE" + list.i("id")))) {
		info.addRow(list.getRow());
		break;
	}
}

//출력
p.setBody("mobile.popup");
p.setVar(info);
p.setVar("banner_block", info.size() > 0);
p.display();

%>