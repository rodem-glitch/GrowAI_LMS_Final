<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.util.*" %>
<%@ page import="malgnsoft.db.*" %>
<%@ page import="malgnsoft.util.*" %>
<%@ page import="malgnsoft.json.*" %>
<%@ include file="../init.jsp" %><%

// -------------------------------------------------------------------
// 목적: 학생 홈 "추천 동영상" 더보기 페이지
// -------------------------------------------------------------------

// 왜: 콜러스 외부 영상은 LMS DB에 없으므로, API 응답(TB_RECO_CONTENT 데이터)을 직접 사용합니다.

int topK = m.ri("topK");
if(topK <= 0) topK = 50;
if(topK > 200) topK = 200;

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

		while(recoRows.next()) {
			String lessonId = recoRows.s("lessonId");  // 콜러스 영상 키값 (예: "5vcd73vW")
			if("".equals(lessonId)) continue;

			recoVideoMoreList.addRow();
			recoVideoMoreList.put("lesson_id", lessonId);
			recoVideoMoreList.put("title", recoRows.s("title"));
			recoVideoMoreList.put("category_nm", recoRows.s("categoryNm"));
			recoVideoMoreList.put("keywords", recoRows.s("keywords"));
			recoVideoMoreList.put("score", recoRows.s("score"));

			// 왜: 콜러스 외부 영상은 콜러스 플레이어로 재생합니다.
			String playUrl = kollus.getPlayUrl(lessonId, "");
			if("https".equals(request.getScheme())) playUrl = playUrl.replace("http://", "https://");
			recoVideoMoreList.put("play_url", playUrl);

			// 왜: 외부 영상은 학습 상태가 없으므로 빈 값 처리
			recoVideoMoreList.put("duration_conv", "");
			recoVideoMoreList.put("status_badge", "");
			recoVideoMoreList.put("last_date_conv", "");
			recoVideoMoreList.put("thumbnail", "/html/images/common/noimage_course.gif");
		}
	}
} catch(Exception ignore) {}

p.setLayout("blank");
p.setBody("mypage.reco_video_more");
p.setVar("p_title", "추천 동영상 더보기");
p.setLoop("reco_video_more_list", recoVideoMoreList);
p.setVar("total_count", recoVideoMoreList.size());
p.display();

%>
