<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(10, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteSkinDao siteSkin = new SiteSkinDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = siteSkin.find("id = '" + id + "'");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel1".equals(m.request("mode"))) {
	if(!"".equals(info.s("main_img"))) {
		siteSkin.item("main_img", "");
		if(!siteSkin.update("id = '" + id + "'")) { }
		m.delFile(m.getUploadPath(info.s("main_img")));
	}
	return;
}
if("fdel2".equals(m.request("mode"))) {
	if(!"".equals(info.s("sub_img"))) {
		siteSkin.item("sub_img", "");
		if(!siteSkin.update("id = '" + id + "'")) { }
		m.delFile(m.getUploadPath(info.s("sub_img")));
	}
	return;
}

//폼체크
f.addElement("skin_nm", info.s("skin_nm"), "hname:'스킨명', required:'Y'");
f.addElement("tpl_root", info.s("tpl_root"), "hname:'HTML 시작 경로', required:'Y'");
f.addElement("base_yn", info.s("base_yn"), "hname:'기본스킨여부', required:'Y'");
f.addElement("main_img", info.s("main_img"), "hname:'메인이미지'");
f.addElement("sub_img", info.s("sub_img"), "hname:'서브이미지'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'"); 

//수정
if(m.isPost() && f.validate()) {


	if(f.getFileName("main_img") != null) {
		File main_img = f.saveFile("main_img");
		if(main_img != null) {
			siteSkin.item("main_img", f.getFileName("main_img"));
		}
	}
	if(f.getFileName("sub_img") != null) {
		File main_img = f.saveFile("sub_img");
		if(main_img != null) {
			siteSkin.item("sub_img", f.getFileName("sub_img"));
		}
	}

	siteSkin.item("skin_nm", f.get("skin_nm"));
	siteSkin.item("tpl_root", f.get("tpl_root"));
	if("Y".equals(f.get("base_yn"))) {
		siteSkin.execute("UPDATE " + siteSkin.table + " SET base_yn = 'N'");
		siteSkin.item("base_yn", "Y");
	} else { siteSkin.item("base_yn", "N"); }
	siteSkin.item("status", f.getInt("status"));

	if(!siteSkin.update("id = '" + id + "'")) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}

	m.jsReplace("skin_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("main_img_conv", m.encode(info.s("main_img")));
info.put("sub_img_conv", m.encode(info.s("sub_img")));
info.put("main_img_path", m.encode(f.uploadDir + "/" + info.i("id") + "_main_img"));
info.put("sub_img_path", m.encode(f.uploadDir + "/" + info.i("id") + "_sub_img"));
info.put("main_img_url", m.getUploadUrl(info.s("main_img")));
info.put("sub_img_url", m.getUploadUrl(info.s("sub_img")));
info.put("reg_date", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

//출력
p.setBody("skin.skin_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("status_list", m.arr2loop(siteSkin.statusList));
p.display();

%>