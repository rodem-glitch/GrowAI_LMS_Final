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
// - 추천 로직은 Spring Boot(polytech-lms-api)에서 처리하고,
// - JSP는 결과를 받아서 레거시 레슨/콜러스 정보로 카드에 필요한 값(썸네일/재생URL 등)을 조립합니다.
// -------------------------------------------------------------------

LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

int topK = m.ri("topK");
if(topK <= 0) topK = 50;
if(topK > 200) topK = 200;

DataSet recoVideoMoreList = new DataSet();

try {
	// 왜: 운영/개발 환경마다 Spring API 주소가 다를 수 있어서, 환경변수로 우선 제어할 수 있게 합니다.
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

		while(recoRows.next()) {
			int lid = m.parseInt(recoRows.s("lessonId"));
			if(lid <= 0) continue;

			DataSet linfo = lesson.find(
				"id = " + lid + " AND site_id = " + siteId + " AND status = 1 AND use_yn = 'Y'",
				"id, lesson_nm, start_url, total_time, lesson_type"
			);
			if(!linfo.next()) continue;

			recoVideoMoreList.addRow();
			recoVideoMoreList.put("lesson_id", lid);
			recoVideoMoreList.put("title", linfo.s("lesson_nm"));
			recoVideoMoreList.put("category_nm", recoRows.s("categoryNm"));
			recoVideoMoreList.put("score", recoRows.s("score"));

			// 재생 URL(미리보기 용도)
			// 왜: 레슨 타입에 따라 재생 경로가 다릅니다.
			// - 05(콜러스)은 토큰 발급이 필요하므로 kollus.getPlayUrl()을 써야 재생됩니다.
			// - 그 외는 jwplayer.jsp 흐름으로 새 탭 미리보기를 엽니다.
			String playUrl = "";
			if("05".equals(linfo.s("lesson_type"))) {
				playUrl = kollus.getPlayUrl(linfo.s("start_url"), "");
				if("https".equals(request.getScheme())) playUrl = playUrl.replace("http://", "https://");
			} else {
				playUrl = "/player/jwplayer.jsp?lid=" + lid + "&cuid=0&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd"));
			}
			recoVideoMoreList.put("play_url", playUrl);

			// 시간 표시(분 단위)
			int totalMin = linfo.i("total_time");
			recoVideoMoreList.put("duration_conv", totalMin > 0 ? (totalMin + "분") : "");

			// 상태 배지(더보기에서는 제외하지 않고 표시만)
			boolean enrolled = "true".equalsIgnoreCase(recoRows.s("enrolled")) || "1".equals(recoRows.s("enrolled")) || "Y".equalsIgnoreCase(recoRows.s("enrolled"));
			boolean watched = "true".equalsIgnoreCase(recoRows.s("watched")) || "1".equals(recoRows.s("watched")) || "Y".equalsIgnoreCase(recoRows.s("watched"));
			boolean completed = "true".equalsIgnoreCase(recoRows.s("completed")) || "1".equals(recoRows.s("completed")) || "Y".equalsIgnoreCase(recoRows.s("completed"));

			String badge = "";
			if(completed) badge = "완료";
			else if(watched) badge = "시청";
			else if(enrolled) badge = "수강중";
			recoVideoMoreList.put("status_badge", badge);

			// 마지막 시청일(있으면)
			String lastDate = recoRows.s("lastDate");
			if(lastDate != null && lastDate.length() >= 14) {
				recoVideoMoreList.put("last_date_conv", m.time(_message.get("format.date.dot"), lastDate));
			} else {
				recoVideoMoreList.put("last_date_conv", "");
			}

			// 썸네일(콜러스는 snapshot_url 사용, 그 외는 기본 이미지)
			String thumbnail = "/html/images/common/noimage_course.gif";
			try {
				if("05".equals(linfo.s("lesson_type")) && !"".equals(linfo.s("start_url"))) {
					DataSet kinfo = kollus.getContentInfo(linfo.s("start_url"));
					if(kinfo.next() && !"".equals(kinfo.s("snapshot_url"))) {
						thumbnail = kinfo.s("snapshot_url");
					}
				}
			} catch(Exception ignore) {}
			recoVideoMoreList.put("thumbnail", thumbnail);
		}
	}
} catch(Exception ignore) {
	// 왜: 추천 서버/네트워크가 잠깐 실패해도 페이지 자체는 떠야 하므로, 목록만 비워 둡니다.
}

p.setLayout("blank");
p.setBody("mypage.reco_video_more");
p.setVar("p_title", "추천 동영상 더보기");
p.setLoop("reco_video_more_list", recoVideoMoreList);
p.display();

%>
