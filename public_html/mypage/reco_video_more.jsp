<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.util.*" %>
<%@ page import="malgnsoft.db.*" %>
<%@ page import="malgnsoft.util.*" %>
<%@ page import="malgnsoft.json.*" %>
<%@ include file="../init.jsp" %>
<%@ include file="/kollus/thumb_util.jspf" %><%

// -------------------------------------------------------------------
// 목적: 학생 홈 "추천 동영상" 더보기 페이지
// -------------------------------------------------------------------

// 왜: 콜러스 외부 영상은 LMS DB에 없으므로, API 응답(TB_RECO_CONTENT 데이터)을 직접 사용합니다.

int topK = m.ri("topK");
if(topK <= 0) topK = 50;
if(topK > 200) topK = 200;

// 사용자 정보 (헤더 표시용)
UserDao user = new UserDao();
StudentRecoPromptDao recoPrompt = new StudentRecoPromptDao();
DataSet uinfo = null;
if(userId > 0) {
	uinfo = user.find("id = " + userId + " AND status = 1");
	if(!uinfo.next()) uinfo = null;
}

// 추천 프롬프트 (왜: 더보기에서도 동일한 추천 기준을 씁니다.)
String studentRecoPrompt = "";
if(userId > 0) {
	DataSet promptInfo = recoPrompt.find(
		"site_id = " + siteId + " AND user_id = " + userId + " AND status = 1",
		"prompt"
	);
	if(promptInfo.next()) {
		studentRecoPrompt = promptInfo.s("prompt");
	}
}

DataSet recoVideoMoreList = new DataSet();

try {
	String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
	if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
	apiBase = apiBase.replaceAll("/+$", "");

	String url = apiBase + "/student/content-recommend/home/more";

	JSONObject payload = new JSONObject();
	if(userId > 0) payload.put("userId", userId);
	payload.put("siteId", siteId);
	payload.put("topK", topK);
	// 왜: 학생이 저장한 프롬프트만 기준으로 추천합니다.
	if(!"".equals(studentRecoPrompt)) payload.put("extraQuery", studentRecoPrompt);

	String responseBody = "";
	int httpCode = 0;

	HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
	conn.setRequestMethod("POST");
	conn.setConnectTimeout(5000);
	conn.setReadTimeout(20000);
	conn.setDoOutput(true);
	conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
	conn.setRequestProperty("Accept", "application/json");

	byte[] bodyBytes = payload.toString().getBytes(StandardCharsets.UTF_8);
	conn.setFixedLengthStreamingMode(bodyBytes.length);
	try(OutputStream os = conn.getOutputStream()) {
		os.write(bodyBytes);
	}

	httpCode = conn.getResponseCode();
	InputStream is = (httpCode >= 200 && httpCode < 300) ? conn.getInputStream() : conn.getErrorStream();
	if(is != null) {
		try(BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
			StringBuilder sb = new StringBuilder();
			String line;
			while((line = br.readLine()) != null) sb.append(line);
			responseBody = sb.toString();
		}
	}

	if(httpCode >= 200 && httpCode < 300) {
		DataSet recoRows = new DataSet();
		try {
			String trimmed = responseBody == null ? "" : responseBody.trim();
			if(trimmed.startsWith("[")) recoRows = malgnsoft.util.Json.decode(trimmed);
		} catch(Exception ignore) {}

		KollusDao kollus = new KollusDao(siteId);

		KollusMediaDao kollusMedia = new KollusMediaDao();
		HashMap<String, String> thumbCache = new HashMap<String, String>();

		// 왜: 추천 목록의 lessonId(콜러스 키)는 TB_KOLLUS_MEDIA에 없을 수 있습니다(찜/매핑 전).
		//     tutor_lms/api/kollus_list.jsp처럼 콜러스 API 목록에서 snapshot_url을 추가로 찾아 썸네일을 맞춥니다.
		HashSet<String> lessonIdSet = new HashSet<String>();
		recoRows.first();
		while(recoRows.next()) {
			String lid = recoRows.s("lessonId");
			if(!"".equals(lid)) lessonIdSet.add(lid);
		}
		recoRows.first();

		HashMap<String, String> kollusThumbMap = new HashMap<String, String>();
		boolean kollusThumbMapLoaded = false;

		String now = m.time("yyyyMMddHHmmss");

		while(recoRows.next()) {
			String lessonId = recoRows.s("lessonId");  // 콜러스 영상 키값 (예: "5vcd73vW")
			if("".equals(lessonId)) continue;

			recoVideoMoreList.addRow();
			recoVideoMoreList.put("lesson_id", lessonId);
			recoVideoMoreList.put("title", recoRows.s("title"));
			recoVideoMoreList.put("category_nm", recoRows.s("categoryNm"));
			recoVideoMoreList.put("keywords", recoRows.s("keywords"));
			recoVideoMoreList.put("score", recoRows.s("score"));

			// 왜: 학생도 교수자처럼 작은 팝업으로 미리보기 재생이 필요합니다.
			String playUrl = "/kollus/preview.jsp?key=" + lessonId;
			recoVideoMoreList.put("play_url", playUrl);

			// 왜: 외부 영상은 학습 상태가 없으므로 빈 값 처리
			recoVideoMoreList.put("duration_conv", "");
			recoVideoMoreList.put("status_badge", "");
			recoVideoMoreList.put("last_date_conv", "");
			// 왜: 가능하면 TB_KOLLUS_MEDIA를 우선 사용하고, 없으면 콜러스 API에서 가져와 캐싱합니다.
			String thumbnail = thumbCache.get(lessonId);
			if(thumbnail == null) {
				// 1차: DB만 조회(콜러스 API 호출 최소화)
				String found = kollusThumbResolveAndCache(siteId, lessonId, recoRows.s("title"), now, kollusMedia, kollusThumbMapLoaded ? kollusThumbMap : null);
				// 2차: DB에 없으면 그때 콜러스 API 목록을 불러와 재시도
				if("".equals(found) && !kollusThumbMapLoaded) {
					kollusThumbMap = kollusThumbBuildMap(kollus, siteinfo, siteId, lessonIdSet, 30);
					kollusThumbMapLoaded = true;
					found = kollusThumbResolveAndCache(siteId, lessonId, recoRows.s("title"), now, kollusMedia, kollusThumbMap);
				}
				if("".equals(found)) found = "/html/images/common/noimage_course.gif";
				thumbCache.put(lessonId, found);
				thumbnail = found;
			}
			recoVideoMoreList.put("thumbnail", thumbnail);
		}
	}
} catch(Exception e) {
	malgnsoft.util.Malgn.errorLog("추천 동영상 더보기 조회 실패(site_id=" + siteId + ", user_id=" + userId + "): " + e.getMessage(), e);
}

// 왜: 메인 "더보기"에서도 동일한 헤더/푸터를 쓰기 위해 신규 레이아웃을 사용합니다.
p.setLayout("new_main");
p.setBody("mypage.reco_video_more");
p.setVar("p_title", "추천 동영상 더보기");
p.setLoop("reco_video_more_list", recoVideoMoreList);
p.setVar("total_count", recoVideoMoreList.size());
p.setVar("login_block", userId > 0 && uinfo != null);
if(userId > 0 && uinfo != null) {
	p.setVar("SYS_USERNAME", uinfo.s("user_nm"));
	String userNameForHeader = uinfo.s("user_nm");
	p.setVar("SYS_USERNAME_INITIAL", userNameForHeader.length() > 0 ? userNameForHeader.substring(0, 1) : "?");
} else {
	p.setVar("SYS_USERNAME", "");
	p.setVar("SYS_USERNAME_INITIAL", "");
}
p.display();

%>
