<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(10, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteSkinDao siteSkin = new SiteSkinDao();

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_base", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(siteSkin.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.base_yn", f.get("s_base"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.skin_nm,a.tpl_root", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.base_yn DESC, a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("base_class", "Y".equals(list.s("base_yn")) ? "base" : "");
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), siteSkin.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "스킨관리(" + m.time("yyyy-MM-dd") + ").xls"); 
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "skin_nm=>스킨명", "tpl_root=>HTML 시작 경로", "base_yn=>기본스킨여부", "main_img=>메인이미지", "sub_img=>서브이미지", "reg_date=>등록일", "status=>상태" }, "스킨관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("skin.skin_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("status_list", m.arr2loop(siteSkin.statusList));
p.display();

%>