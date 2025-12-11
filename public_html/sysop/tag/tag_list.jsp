<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(712, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }


//객체
TagDao tag = new TagDao(siteId);
TagModuleDao tagModule = new TagModuleDao();

//폼체크
f.addElement("s_module", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//변수
String mode = m.rs("mode");

if(m.isPost() && "sort".equals(mode)) {
	DataSet sortList = f.getArrList(new String[] { "id", "sort" });
	while(sortList.next()) {
		tag.execute("UPDATE " + tag.table + " SET sort = " + sortList.i("sort") + " WHERE id = " + sortList.i("id") + "");
	}

	m.jsReplace("tag_list.jsp?" + m.qs("id,mode,sort"), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(mode) ? sysExcelCnt : f.getInt("s_listnum", 20));
lm.setTable(
	tag.table + " a "
);
lm.setFields(
	"a.* "
	+ ", (SELECT COUNT(*) FROM " + tagModule.table + " WHERE tag_id = a.id AND module = 'course') course_cnt "
);
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
if("course".equals(f.get("s_module"))) lm.addWhere("EXISTS (SELECT 1 FROM " + tagModule.table + " WHERE tag_id = a.id AND module = 'course')");
lm.addSearch("a.id", f.get("tag_id"));
lm.addSearch("a.tag_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.sort ASC, a.id ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", Malgn.time("yyyy.MM.dd", list.s("reg_date")));
}

//엑셀
if("excel".equals(mode)) {
	ExcelWriter ex = new ExcelWriter(response, Menu.menuNm + "(" + Malgn.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "tag_nm=>태그명", "course_cnt=>사용과정수", "reg_date_conv=>태그등록일", "sort=>순서"  }, Menu.menuNm + "(" + Malgn.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout(ch);
p.setBody("tag.tag_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("list_total_num", Malgn.nf(lm.getTotalNum()));

p.setLoop("status_list", Malgn.arr2loop(tag.statusList));
p.setLoop("module_list", Malgn.arr2loop(tagModule.moduleList));

p.display();

%>