<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(11, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BannerDao banner = new BannerDao();
banner.siteId = siteId;

//변수
int maxSort = banner.findCount("site_id = " + siteId + " AND banner_type = 'main' AND status > -1");

//폼체크
f.addElement("banner_type", null, "hname:'구분', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.'");
f.addElement("banner_nm", null, "hname:'배너명', required:'Y'");
f.addElement("banner_text", null, "hname:'배너 텍스트'");
f.addElement("link", "http://", "hname:'링크'");
f.addElement("target", "_self", "hname:'링크타겟'");
f.addElement("banner_file", null, "hname:'이미지', allow:'jpg|gif|png|jpeg'");
f.addElement("banner_url", null, "hname:'외부이미지 URL'");
f.addElement("sort", (maxSort + 1), "hname:'순서', required:'Y', option:'number'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");
//f.addElement("width", null, "hname:'가로사이즈'");
//f.addElement("height", null, "hname:'세로사이즈'");	

//등록
if(m.isPost() && f.validate()) {

	//제한-배너구분
	if(!f.get("banner_type").matches("^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$")) {
		m.jsAlert("구분은 영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.");
		return;
	}

	int newId = banner.getSequence();

	banner.item("id", newId);
	banner.item("site_id", siteinfo.i("id"));
	banner.item("banner_type", f.get("banner_type"));
	banner.item("banner_nm", f.get("banner_nm"));
	banner.item("banner_text", f.get("banner_text"));
	banner.item("link", f.get("link"));
	banner.item("target", f.get("target"));
	//banner.item("width", f.getInt("width"));
	//banner.item("height", f.getInt("height"));
	banner.item("width", 0);
	banner.item("height", 0);
	
	if(null != f.getFileName("banner_file")) {
		File f1 = f.saveFile("banner_file");
		if(null != f1) banner.item("banner_file", f.getFileName("banner_file"));
	}
	banner.item("banner_url", f.get("banner_url"));
	banner.item("reg_date", m.time("yyyyMMddHHmmss"));
	banner.item("status", f.getInt("status"));

	if(!banner.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	//순서정렬
	banner.sortBanner(banner.getInsertId(), f.getInt("sort"), maxSort + 1);

	//이동
	m.jsReplace("banner_list.jsp", "parent");
	return;
}

//순서
DataSet sortList = new DataSet();
for(int i=0; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//출력
p.setBody("banner.banner_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("types", banner.query("SELECT DISTINCT banner_type FROM " + banner.table + " WHERE banner_type NOT IN ('main', 'mobile') AND site_id = " + siteId + " AND status != -1"));
p.setLoop("targets", m.arr2loop(banner.targets));
p.setLoop("sorts", sortList);
p.setLoop("status_list", m.arr2loop(banner.statusList));
p.display();

%>