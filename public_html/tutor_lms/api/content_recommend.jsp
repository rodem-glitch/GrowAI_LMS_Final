<%@ page pageEncoding="utf-8" %><%@ page import="java.io.*" %><%@ page import="java.net.*" %><%@ page import="java.nio.charset.StandardCharsets" %><%@ page import="java.util.*" %><%@ page import="malgnsoft.db.*" %><%@ page import="malgnsoft.util.*" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 교수자 화면(과목/차시 구성)에서 "콘텐츠 검색"을 눌렀을 때, 입력된 과목/차시 정보를 기반으로 추천 목록을 내려줘야 합니다.
//- 프론트는 같은 도메인의 `/tutor_lms/api/*`만 호출하므로, Spring Boot(polytech-lms-api) 추천 엔드포인트를 프록시해 줍니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String courseName = m.rs("course_name").trim();
String courseIntro = m.rs("course_intro").trim();
String courseDetail = m.rs("course_detail").trim();
String lessonTitle = m.rs("lesson_title").trim();
String lessonDescription = m.rs("lesson_description").trim();
String keywords = m.rs("keywords").trim();

int topK = m.ri("top_k");
if(topK <= 0) topK = 50;
if(topK > 50) topK = 50;

double similarityThreshold = 0.2;
try {
	String thresholdParam = m.rs("similarity_threshold").trim();
	if(!"".equals(thresholdParam)) similarityThreshold = Double.parseDouble(thresholdParam);
} catch(Exception ignore) {}
if(similarityThreshold <= 0) similarityThreshold = 0.2;
if(similarityThreshold > 1.0) similarityThreshold = 1.0;


// 왜: 운영/개발 환경마다 Spring API 주소가 다를 수 있어서, 환경변수로 우선 제어할 수 있게 합니다.
String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
apiBase = apiBase.replaceAll("/+$", "");

String url = apiBase + "/tutor/content-recommend/lessons";

JSONObject payload = new JSONObject();
payload.put("courseName", courseName);
payload.put("courseIntro", courseIntro);
payload.put("courseDetail", courseDetail);
payload.put("lessonTitle", lessonTitle);
payload.put("lessonDescription", lessonDescription);
payload.put("keywords", keywords);
payload.put("topK", topK);
payload.put("similarityThreshold", similarityThreshold);

String responseBody = "";
int httpCode = 0;

try {
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
} catch(Exception e) {
	result.put("rst_code", "5001");
	result.put("rst_message", "추천 서버 호출 중 오류가 발생했습니다.");
	result.print();
	return;
}

if(httpCode < 200 || httpCode >= 300) {
	result.put("rst_code", "5002");
	result.put("rst_message", "추천 서버 응답이 올바르지 않습니다. (" + httpCode + ")");
	result.print();
	return;
}

DataSet recoRows = new DataSet();
try {
	String trimmed = responseBody == null ? "" : responseBody.trim();
	if(trimmed.startsWith("[")) {
		recoRows = malgnsoft.util.Json.decode(trimmed);
	}
} catch(Exception ignore) {
	// 왜: 추천 서버가 JSON 배열을 돌려주지 못한 경우에도, 교수자 화면이 깨지지 않게 안전하게 실패 처리합니다.
}

LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

DataSet list = new DataSet();

while(recoRows.next()) {
	String lessonIdStr = recoRows.s("lessonId");
	if("".equals(lessonIdStr)) continue;

	int lessonId = m.parseInt(lessonIdStr);
	if(lessonId <= 0) continue;

	DataSet linfo = lesson.find(
		"id = " + lessonId + " AND site_id = " + siteId + " AND status = 1",
		"id, lesson_nm, start_url, total_time, content_width, content_height, lesson_type"
	);
	if(!linfo.next()) continue;

	String mediaKey = linfo.s("start_url");

	list.addRow();
	list.put("id", String.valueOf(lessonId));            //프론트 선택키
	list.put("lesson_id", String.valueOf(lessonId));     //실제 레슨ID
	list.put("media_content_key", mediaKey);             //콜러스 키(있으면)
	list.put("title", linfo.s("lesson_nm"));
	list.put("category_nm", recoRows.s("categoryNm"));
	list.put("total_time", linfo.s("total_time"));
	list.put("content_width", linfo.s("content_width"));
	list.put("content_height", linfo.s("content_height"));
	list.put("score", recoRows.s("score"));

	// 왜: 추천 탭에서도 가능한 한 기존 "전체 탭"과 같은 컬럼(썸네일/원본파일/재생시간)을 보여주면 사용자가 선택하기 쉽습니다.
	try {
		if(!"".equals(mediaKey) && "05".equals(linfo.s("lesson_type"))) {
			DataSet kinfo = kollus.getContentInfo(mediaKey);
			if(kinfo.next()) {
				list.put("thumbnail", kinfo.s("snapshot_url"));
				list.put("snapshot_url", kinfo.s("snapshot_url"));
				list.put("original_file_name", kinfo.s("original_file_name"));
				list.put("duration", kinfo.s("duration"));
			}
		}
	} catch(Exception ignore) {}
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_total", list.size());
result.put("rst_data", list);
result.print();

%>
