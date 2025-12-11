<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

PopupDao popup = new PopupDao();

if(m.ri("id") > 0) {
	if("".equals(m.rs("ek")) || !m.encrypt(m.rs("id")).equals(m.rs("ek"))) return;
	DataSet info = popup.find("id = " + m.ri("id") + " AND popup_type = 'pc' AND site_id = " + siteId + " AND status = 1");
	if(info.next()) {
		p.setVar(info);
		if("Y".equals(info.s("template_yn")) && !"".equals(info.s("layout"))) {
			p.print(out, "../html/pop_template/" + info.s("layout") + ".html");
		} else {
			p.setLayout("blank");
			p.setBody("main.popup");
			p.display();
			
		}
	}

} else {
	DataSet list = popup.find("popup_type = 'pc' AND site_id = " + siteId + " AND status = 1 AND '" + m.time("yyyyMMdd") + "' BETWEEN start_date AND end_date", "*", "id ASC");
	int cnt = 0;
	while(list.next()) {
		cnt++;
		DataSet info = new DataSet();
		info.addRow(list.getRow());

		if("done".equals(m.getCookie("POPUP" + list.i("id")))) {
			list.put("display", "display:none");
			list.put("remove_block", true);
			list.put("content", "");
			continue;
		}

		list.put("display", "display:block");
		list.put("remove_block", false);
		if(list.i("top_pos") == 0 ) {
			list.put("top_pos_conv", "top:50%" + ";margin-top:" + (-(list.i("height")/2) + "px" ));
		} else {
			list.put("top_pos_conv", "top:" + list.i("top_pos") + "px");
		}
		if(list.i("left_pos") == 0 ) {
			list.put("left_pos_conv", "left:50%" + ";margin-left:" + (-(list.i("width")/2) + "px" ));
		} else {
			list.put("left_pos_conv", "left:" + list.i("left_pos") + "px");
		}
		list.put("template_yn", "Y".equals(list.s("template_yn")));
	}
	p.setBody("main.popup");
	p.setLoop("list", list);
	p.display();
}

%>