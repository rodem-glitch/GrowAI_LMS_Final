<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(137, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao();

//코드체크
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < ktalkTemplate.findCount("site_id = " + siteId + " AND template_cd = '" + value + "'")) {
		out.print("<span class='bad'>사용 중인 코드입니다. 다시 입력해 주세요.</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 코드입니다.</span>");
	}
	return;
}

//폼체크
f.addElement("template_cd", null, "hname:'템플릿코드', required:'Y', max:20, maxlength:20, pattern:'^[a-z]{1}[a-z0-9_]{1,19}$', errmsg:'영문 소문자로 시작하는 2-10자의 영문 소문자, 숫자, _ 조합으로 입력하세요.'");
f.addElement("ktalk_cd", null, "hname:'알림톡코드', required:'Y', max:20, maxlength:20, pattern:'^[a-z]{1}[a-z0-9_]{1,19}$', errmsg:'영문 소문자로 시작하는 2-10자의 영문 소문자, 숫자, _ 조합으로 입력하세요.'");
f.addElement("template_nm", null, "hname:'템플릿명', required:'Y'");
f.addElement("content", null, "hname:'내용'");
for(int i = 1; i <= icnt; i++) {
	f.addElement("item" + i + "_txt", null, "hname:'항목명" + i + "'");
	f.addElement("item" + i + "_var", null, "hname:'변수명" + i + "'");
}
f.addElement("course_yn", null, "hname:'과정수강생사용여부'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	//중복검사-코드
	if(0 < ktalkTemplate.findCount("site_id = " + siteId + " AND template_cd = '" + f.get("template_cd") + "' AND ktalk_cd = '" + f.get("ktalk_cd") + "' AND status != -1")) { m.jsAlert("사용 중인 코드입니다. 다시 입력해 주세요."); return; }

	DataSet iifno = new DataSet(); iifno.addRow();
	for(int i = 1; i <= icnt; i++) {
		iifno.put("item" + i + "_txt", f.get("item" + i + "_txt"));
		iifno.put("item" + i + "_var", f.get("item" + i + "_var"));
	}

	ktalkTemplate.item("site_id", siteId);
	ktalkTemplate.item("template_cd", f.get("template_cd"));
	ktalkTemplate.item("ktalk_cd", f.get("ktalk_cd"));
	ktalkTemplate.item("template_nm", f.get("template_nm"));
	String content = m.replace(f.get("content"), new String[] {"#{", "}"}, new String[] {"{{","}}"});
	ktalkTemplate.item("content", content);
	ktalkTemplate.item("base_yn", "N");
	ktalkTemplate.item("items", iifno.serialize());
	ktalkTemplate.item("course_yn", f.get("course_yn", "N"));
	ktalkTemplate.item("reg_date", m.time("yyyyMMddHHmmss"));
	ktalkTemplate.item("status", f.get("status", "0"));

	if(!ktalkTemplate.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("template_list.jsp?" + m.qs(), "parent");
	return;
}


//목록
DataSet items = new DataSet();
for(int i = 1; i <= icnt; i++) {
	items.addRow();
	items.put("__ord", i);
}

//출력
p.setBody("ktalk.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("items", items);
p.setVar("icnt", icnt);
p.setVar("ccnt", icnt+1);
p.setLoop("status_list", m.arr2loop(ktalkTemplate.statusList));
p.display();

%>