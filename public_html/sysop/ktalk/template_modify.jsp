<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(137, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao();

//정보
DataSet info = ktalkTemplate.query(
	" SELECT a.* "
	+ " FROM " + ktalkTemplate.table + " a "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), ktalkTemplate.statusList));
info.put("content", m.replace(info.s("content"), new String[] {"{{","}}"}, new String[] {"#{", "}"}));

//항목
DataSet iinfo = new DataSet();
if(!"".equals(info.s("items")) && !"[]".equals(info.s("items"))) iinfo.unserialize(info.s("items"));

//폼체크
f.addElement("ktalk_cd", info.s("ktalk_cd"), "hname:'알림톡코드', required:'Y', max:20, maxlength:20, pattern:'^[a-z]{1}[a-z0-9_]{1,19}$', errmsg:'영문 소문자로 시작하는 2-10자의 영문 소문자, 숫자, _ 조합으로 입력하세요.'");
f.addElement("template_nm", info.s("template_nm"), "hname:'템플릿명', required:'Y'");
f.addElement("content", info.s("content"), "hname:'내용'");
for(int i = 1; i <= icnt; i++) {
	f.addElement("item" + i + "_txt", iinfo.s("item" + i + "_txt"), "hname:'항목명" + i + "'");
	f.addElement("item" + i + "_var", iinfo.s("item" + i + "_var"), "hname:'변수명" + i + "'");
}
f.addElement("course_yn", info.s("course_yn"), "hname:'과정수강생사용여부'");
f.addElement("status", info.s("status"), "hname:'상태'");


//수정
if(m.isPost() && f.validate()) {

	//중복검사-코드
	if(0 < ktalkTemplate.findCount("site_id = " + siteId + " AND template_cd = '" + info.s("template_cd") + "' AND ktalk_cd = '" + f.get("ktalk_cd") + "' AND status != -1 AND id != " + id + "")) { m.jsAlert("사용 중인 코드입니다. 다시 입력해 주세요."); return; }

	iinfo.removeAll(); iinfo.addRow();
	for(int i = 1; i <= icnt; i++) {
		iinfo.put("item" + i + "_txt", f.get("item" + i + "_txt"));
		iinfo.put("item" + i + "_var", f.get("item" + i + "_var"));
	}

	//if(isUserMaster) {
		ktalkTemplate.item("ktalk_cd", f.get("ktalk_cd"));
		ktalkTemplate.item("template_nm", f.get("template_nm"));
		String content = m.replace(f.get("content"), new String[] {"#{", "}"}, new String[] {"{{","}}"});
		ktalkTemplate.item("content", content);
		ktalkTemplate.item("items", iinfo.serialize());
		ktalkTemplate.item("course_yn", f.get("course_yn", "N"));
	//}
	ktalkTemplate.item("status", f.get("status", "1"));

	if(!ktalkTemplate.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("template_list.jsp?" + m.qs("id"), "parent");
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

p.setVar("modify", true);
p.setVar(info);

p.setLoop("items", items);
p.setVar("icnt", icnt);
p.setVar("ccnt", icnt+1);
p.setLoop("status_list", m.arr2loop(ktalkTemplate.statusList));
p.display();

%>