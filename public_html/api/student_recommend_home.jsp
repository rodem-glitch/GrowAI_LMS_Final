<%@ page contentType="application/json; charset=utf-8" %><%@ page pageEncoding="utf-8" %><%@ page import="java.io.*" %><%@ page import="java.net.*" %><%@ page import="java.nio.charset.StandardCharsets" %><%@ page import="java.util.*" %><%@ page import="malgnsoft.db.*" %><%@ page import="malgnsoft.util.*" %><%@ page import="malgnsoft.json.*" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- 학생 메인 화면에서 "학과/전공/수강과목 기반" 추천을 보여주려면, 로그인 사용자 정보를 이용해 추천 쿼리를 자동으로 만들어야 합니다.
//- 프론트(레거시/템플릿)는 동일 도메인의 JSP를 쉽게 호출할 수 있으므로, Spring Boot(polytech-lms-api) 추천 엔드포인트를 프록시합니다.

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

int topK = m.ri("top_k");
if(topK <= 0) topK = 20;
if(topK > 50) topK = 50;

double similarityThreshold = 0.2;
try {
	String thresholdParam = m.rs("similarity_threshold").trim();
	if(!"".equals(thresholdParam)) similarityThreshold = Double.parseDouble(thresholdParam);
} catch(Exception ignore) {}
if(similarityThreshold <= 0) similarityThreshold = 0.2;
if(similarityThreshold > 1.0) similarityThreshold = 1.0;

String extraQuery = m.rs("q").trim(); //선택: 학생이 추가로 입력한 관심사/요청

//학과명(가능한 범위)
String deptName = "";
try {
	if(userDeptId > 0) {
		DataObject dept = new DataObject("TB_USER_DEPT");
		deptName = dept.getOne(
			"SELECT dept_nm FROM TB_USER_DEPT WHERE id = " + userDeptId + " AND site_id = " + siteId + " AND status = 1"
		);
	}
} catch(Exception ignore) {}

//수강과목명(최근/진행중 위주로 최대 20개)
List<String> courseNames = new ArrayList<String>();
try {
	DataObject cu = new DataObject("LM_COURSE_USER");
	String today = m.time("yyyyMMdd");
	DataSet rs = cu.query(
		"SELECT c.course_nm "
		+ " FROM LM_COURSE_USER cu "
		+ " JOIN LM_COURSE c ON c.id = cu.course_id AND c.site_id = cu.site_id AND c.status = 1 "
		+ " WHERE cu.site_id = " + siteId + " AND cu.user_id = " + userId + " AND cu.status IN (1, 3) "
		+ " AND (cu.end_date = '' OR cu.end_date >= '" + today + "') "
		+ " ORDER BY cu.id DESC "
		+ " LIMIT 20 "
	);
	while(rs.next()) {
		String nm = rs.s("course_nm").trim();
		if(!"".equals(nm) && !courseNames.contains(nm)) courseNames.add(nm);
	}
} catch(Exception ignore) {}

//Spring API 주소
String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
apiBase = apiBase.replaceAll("/+$", "");
String url = apiBase + "/student/content-recommend/home";

JSONObject payload = new JSONObject();
payload.put("deptName", deptName);
payload.put("majorName", ""); //현재 DB에 명확한 전공 컬럼이 없어 비워둡니다(추후 확장).
payload.put("courseNames", courseNames);
payload.put("extraQuery", extraQuery);
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

