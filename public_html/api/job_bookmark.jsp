<%@ page contentType="application/json; charset=utf-8" %>
<%@ page import="dao.*,malgnsoft.db.*,malgnsoft.util.*" %>
<%@ page import="org.json.JSONObject,org.json.JSONArray" %>
<%@ include file="/init.jsp" %><%

// -------------------------------------------------------------------
// 목적: 채용 북마크 DB 저장/삭제/목록 API
// 왜 필요한가:
// - 채용 화면(job-test.html)에는 북마크 버튼 UI가 있지만, 현재는 DB 저장이 없습니다.
// - 먼저 DB/API를 만들어두면, 나중에 화면에서 “저장 목록 보기”만 붙이면 됩니다.
// -------------------------------------------------------------------

Json j = new Json(out);
JobBookmarkDao jobBookmark = new JobBookmarkDao();

try {
	// 공통: 로그인 필요
	if(userId <= 0) {
		j.print(-401, "로그인이 필요합니다.");
		return;
	}

	String mode = m.rs("mode").trim();
	String now = sysNow;

	// 입력값(공통)
	String provider = m.rs("provider").trim().toUpperCase();
	String wantedAuthNo = m.rs("wanted_auth_no").trim();

	// 왜: provider/wantedAuthNo는 유일키에 들어가므로, 최소한의 안전성 검사로 이상값을 막습니다.
	if(!"".equals(provider) && !provider.matches("^[A-Z0-9_\\-]{1,20}$")) provider = "";
	if(!"".equals(wantedAuthNo) && !wantedAuthNo.matches("^[A-Za-z0-9_\\-]{1,60}$")) wantedAuthNo = "";

if("add".equals(mode)) {
	// 저장(등록/복구)
	if(!m.isPost()) { j.print(-405, "POST만 허용됩니다."); return; }

	if("".equals(wantedAuthNo)) { j.print(-1, "wanted_auth_no가 필요합니다."); return; }
	if("".equals(provider)) provider = "WORK24";

	String wantedInfoUrl = m.rs("wanted_info_url").trim();
	String title = m.rs("title").trim();
	String company = m.rs("company").trim();
	String region = m.rs("region").trim();
	String closeDt = m.rs("close_dt").trim();
	String itemJson = m.rs("item_json").trim();

	// 왜: DB 컬럼 길이를 넘기면 저장이 실패하므로, 여기서 안전하게 잘라줍니다.
	if(wantedInfoUrl.length() > 400) wantedInfoUrl = wantedInfoUrl.substring(0, 400);
	if(title.length() > 300) title = title.substring(0, 300);
	if(company.length() > 200) company = company.substring(0, 200);
	if(region.length() > 200) region = region.substring(0, 200);
	if(closeDt.length() > 20) closeDt = closeDt.substring(0, 20);
	// 왜: mediumtext이지만, 과도하게 큰 값은 저장/응답/성능에 악영향이어서 테스트용 상한을 둡니다.
	if(itemJson.length() > 60000) itemJson = itemJson.substring(0, 60000);

	if(!jobBookmark.saveBookmark(siteId, userId, provider, wantedAuthNo, wantedInfoUrl, title, company, region, closeDt, itemJson, now)) {
		j.print(-1, "북마크 저장에 실패했습니다.");
		return;
	}
	j.print(0, "저장했습니다.");
	return;

} else if("del".equals(mode)) {
	// 삭제(소프트삭제)
	if(!m.isPost()) { j.print(-405, "POST만 허용됩니다."); return; }

	if("".equals(wantedAuthNo)) { j.print(-1, "wanted_auth_no가 필요합니다."); return; }
	if("".equals(provider)) provider = "WORK24";

	if(!jobBookmark.deleteBookmark(siteId, userId, provider, wantedAuthNo, now)) {
		j.print(-1, "북마크 삭제에 실패했습니다.");
		return;
	}
	j.print(0, "삭제했습니다.");
	return;

} else if("list".equals(mode)) {
	// 목록
	int pageNo = m.ri("page"); if(pageNo < 1) pageNo = 1;
	int size = m.ri("size"); if(size < 1) size = 50; if(size > 200) size = 200;

	int total = jobBookmark.getCount(siteId, userId);
	DataSet list = jobBookmark.getList(siteId, userId, pageNo, size);

	JSONArray items = new JSONArray();
	while(list.next()) {
		JSONObject row = new JSONObject();
		row.put("id", list.i("id"));
		row.put("provider", list.s("provider"));
		row.put("wanted_auth_no", list.s("wanted_auth_no"));
		row.put("wanted_info_url", list.s("wanted_info_url"));
		row.put("title", list.s("title"));
		row.put("company", list.s("company"));
		row.put("region", list.s("region"));
		row.put("close_dt", list.s("close_dt"));
		row.put("item_json", list.s("item_json"));
		row.put("reg_date", list.s("reg_date"));
		items.put(row);
	}

	JSONObject payload = new JSONObject();
	payload.put("total", total);
	payload.put("page", pageNo);
	payload.put("size", size);
	payload.put("items", items);

	j.setJson(payload.toString());
	j.print(0, "success");
	return;
}

j.print(-1, "mode가 올바르지 않습니다. (add/del/list)");

} catch(Throwable e) {
	// 왜: JSP 예외가 그대로 노출되면 화면/콘솔에서 원인 파악이 어렵고, 500으로만 보입니다.
	Exception ex = (e instanceof Exception) ? (Exception)e : new Exception(e);
	Malgn.errorLog("{api.job_bookmark} error", ex);
	j.print(-1, "북마크 처리 중 오류가 발생했습니다. " + (e.getMessage() == null ? "" : e.getMessage()));
}

%>
