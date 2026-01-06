<%@ page contentType="application/json; charset=utf-8" %><%@ page pageEncoding="utf-8" %><%@ page import="java.io.*" %><%@ page import="java.net.*" %><%@ page import="java.nio.charset.StandardCharsets" %><%@ page import="malgnsoft.db.*" %><%@ page import="malgnsoft.util.*" %><%@ page import="malgnsoft.json.*" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- 학생이 입력한 자연어 검색어로 전체 영상 추천(벡터 유사도 검색)을 제공해야 합니다.
//- 레거시 화면에서 바로 호출할 수 있도록, Spring Boot 추천 엔드포인트를 JSP로 프록시합니다.

response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

if(0 == userId) {
	result.put("rst_code", "4010");
	result.put("rst_message", "로그인이 필요합니다.");
	result.print();
	return;
}

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String query = m.rs("q").trim();
if("".equals(query)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "검색어(q)가 필요합니다.");
	result.print();
	return;
}

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

String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
apiBase = apiBase.replaceAll("/+$", "");
String url = apiBase + "/student/content-recommend/search";

JSONObject payload = new JSONObject();
payload.put("query", query);
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
	try(OutputStream os = conn.getOutputStream()) { os.write(bodyBytes); }

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
	if(trimmed.startsWith("[")) recoRows = malgnsoft.util.Json.decode(trimmed);
} catch(Exception ignore) {}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_total", recoRows.size());
result.put("rst_data", recoRows);
result.print();

%>

