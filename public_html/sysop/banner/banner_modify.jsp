<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(11, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(0 == id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BannerDao banner = new BannerDao(siteId);
banner.siteId = siteId;

//정보
DataSet info = banner.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("banner_type", info.s("banner_type"), "hname:'구분', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.'");
f.addElement("banner_nm", info.s("banner_nm"), "hname:'배너명', required:'Y'");
f.addElement("banner_text", null, "hname:'배너 텍스트'");
//f.addElement("link", info.s("link"), "hname:'URL', pattern:'^(http:\\/\\/)(.+)'");
f.addElement("link", info.s("link"), "hname:'URL'");
f.addElement("target", info.s("target"), "hname:'링크타겟'");
//f.addElement("width", info.i("width"), "hname:'가로사이즈', option:'number', required:'Y'");
//f.addElement("height", info.i("height"), "hname:'세로사이즈', option:'number', required:'Y'");
f.addElement("banner_file", null, "hname:'이미지'");
f.addElement("banner_url", info.s("banner_url"), "hname:'외부이미지 URL'");
f.addElement("sort", info.i("sort"), "hname:'순서', option:'number', required:'Y'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'");

//삭제-첨부파일
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("banner_file"))) {
		banner.item("banner_file", "");
		if(!banner.update("id = " + info.i("id"))) {}
		m.delFileRoot(m.getUploadPath(info.s("banner_file")));
	}
	return;
}

//수정
if(m.isPost() && f.validate()) {

	//제한-배너구분
	if(!f.get("banner_type").matches("^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$")) {
		m.jsAlert("구분은 영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.");
		return;
	}

	banner.item("site_id", siteinfo.i("id"));
	banner.item("banner_type", f.get("banner_type"));
	banner.item("banner_nm", f.get("banner_nm"));
	banner.item("banner_text", f.get("banner_text"));
	banner.item("link", f.get("link"));
	banner.item("target", f.get("target"));
	//banner.item("width", f.getInt("width"));
	//banner.item("height", f.getInt("height"));

	if(null != f.getFileName("banner_file")) {
		File f1 = f.saveFile("banner_file");
		if(null != f1) banner.item("banner_file", f.getFileName("banner_file"));
	}
	banner.item("banner_url", f.get("banner_url"));
	banner.item("status", f.getInt("status"));

	if(!banner.update("id = " + id)) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}

	//순서변경
	int maxSort = banner.findCount("site_id = " + siteId + " AND banner_type = '" + f.get("banner_type") + "' AND status > -1"); //변경구분갯수
	if(f.get("banner_type").equals(info.s("banner_type"))) { //구분미변경
		banner.sortBanner(info.i("id"), f.getInt("sort"), maxSort); //재정렬
	} else { //구분변경
		banner.autoSort(info.s("banner_type")); //이전구분정렬
		banner.sortBanner(info.i("id"), f.getInt("sort"), maxSort); //변경구분정렬
	}

	//캐시삭제
	banner.removeCache(id);

	//이동
	m.jsReplace("banner_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("banner_file_path", m.getUploadPath(info.s("banner_file")));
info.put("banner_file_conv", m.encode(info.s("banner_file")));
info.put("banner_file_url", m.getUploadUrl(info.s("banner_file")));
info.put("banner_file_ek", m.encrypt(info.s("banner_file") + m.time("yyyyMMdd")));

//목록-기존구분순서갯수
int sortCount = banner.findCount("site_id = " + siteId + " AND banner_type = '" + info.s("banner_type") + "' AND status > -1");
DataSet sortList = new DataSet();
for(int i=1; i<=sortCount; i++) {
	sortList.addRow();
	sortList.put("idx", i);
}

//출력
p.setBody("banner.banner_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

//p.setLoop("types", m.arr2loop(banner.types));
p.setLoop("types", banner.query("SELECT DISTINCT banner_type FROM " + banner.table + " WHERE banner_type NOT IN ('main', 'mobile') AND site_id = " + siteId + " AND status != -1"));
p.setLoop("targets", m.arr2loop(banner.targets));
p.setLoop("status_list", m.arr2loop(banner.statusList));
p.setLoop("sorts", sortList);
p.display();

%>