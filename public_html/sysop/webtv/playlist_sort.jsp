<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(927, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(0 == cid) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//폼입력
String mode = m.rs("mode");

//폼체크
f.addElement("cid", cid, null);

//객체
WebtvDao webtv = new WebtvDao();
WebtvPlaylistDao webtvPlaylist = new WebtvPlaylistDao(siteId);
LmCategoryDao webtvCategory = new LmCategoryDao("webtv");
LmCategoryDao playlistCategory = new LmCategoryDao("webtv_playlist");
MCal mcal = new MCal(); mcal.yearRange = 10;

//정보
DataSet info = playlistCategory.find("id = " + cid + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//처리
if("add".equals(mode)) {
	if("".equals(m.rs("widx"))) {
		m.jsError("기본키는 반드시 지정해야 합니다.");
		return;
	}

	if(0 == webtv.findCount("id IN (" + m.rs("widx") + ") AND site_id = " + siteId + " AND status != -1")) {
		m.jsError("해당 방송정보가 없습니다.");
		return;
	}

	String[] idx = m.split(",", m.rs("widx"));
	int failed = 0;

	webtvPlaylist.setInsertIgnore(true);
	webtvPlaylist.item("site_id", siteId);
	webtvPlaylist.item("category_id", cid);
	for(int i = 0; i < idx.length; i++) {
		webtvPlaylist.item("webtv_id", idx[i]);
		webtvPlaylist.item("sort", webtvPlaylist.getLastSort(cid));
		if(!webtvPlaylist.insert()) failed++;
	}

	if(0 < failed) {
		//m.jsError("과정을 등록하는 중 오류가 발생했습니다. " + failed);
	}

	m.redirect("playlist_sort.jsp?cid=" + cid);
	return;

} else if("del".equals(mode)) {
	if(0 == webtv.findCount("id = " + m.ri("id") + " AND site_id = " + siteId + " AND status != -1")) {
		m.jsError("해당 방송정보가 없습니다.");
		return;
	}
	webtvPlaylist.delete("site_id = " + siteId + " AND category_id = " + cid + " AND webtv_id = " + m.ri("id"));
	m.redirect("playlist_sort.jsp?cid=" + cid);
	return;

} else if("sort".equals(mode)) {
	String[] idx = m.reqArr("idx");
	if(idx == null) {
		m.jsError("해당 과정정보가 없습니다.");
		return;
	}

	for(int i = 0; i < idx.length; i++) {
		webtvPlaylist.item("sort", i);
		webtvPlaylist.update("site_id = " + siteId + " AND category_id = " + cid + " AND webtv_id = " + idx[i]);
	}
	m.redirect("playlist_sort.jsp?cid=" + cid);
	return;
}

//카테고리
DataSet categories = webtvCategory.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(webtvPlaylist.table + " p JOIN " + webtv.table + " a ON a.id = p.webtv_id");
lm.setFields("a.*, p.sort");
lm.addWhere("a.status != -1");
lm.addWhere("p.site_id = " + siteId);
lm.addWhere("p.category_id = " + cid);
lm.setOrderBy("p.sort ASC");
//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("category_nm", webtvCategory.getTreeNames(list.i("category_id")));
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 50));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));
	list.put("subtitle_conv", m.stripTags(list.s("subtitle")));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), webtv.displayList));
	list.put("status_conv", m.getItem(list.s("status"), webtv.statusList));

	list.put("open_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("open_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
}

//출력
p.setLayout("blank");
p.setBody("webtv.playlist_sort");
p.setLoop("list", list);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("cid", cid);
p.setVar("form_script", f.getScript());

p.setVar("tab_sort", "current");
p.display();

%>
