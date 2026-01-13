<%@ page import="java.io.*" %><%@ page import="java.net.*" %><%@ page import="java.nio.charset.StandardCharsets" %><%@ page import="java.util.*" %><%@ page import="malgnsoft.db.*" %><%@ page import="malgnsoft.util.*" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- 통계 대시보드(정적 HTML)는 `/statistics/api/*`로 데이터를 받아서 화면을 그립니다.
//- 그런데 교수자 LMS(Resin/JSP)와 통계 서버(polytech-lms-api, Spring Boot)는 보통 다른 포트/서버라서
//  프론트가 바로 `/statistics/api/*`를 호출하면 404 또는 CORS 문제가 납니다.
//- 그래서 교수자 도메인(`/tutor_lms`) 안에서 이 JSP가 Spring API를 대신 호출(프록시)해 주면,
//  사용자 입장에서는 "교수자 페이지 안에서" 통계가 정상 동작합니다.

// -------------------- 권한 체크 --------------------

response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

if(0 == userId) {
	response.setStatus(401);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"로그인이 필요합니다.\"}");
	return;
}

boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);
UserDao authUser = new UserDao();
DataSet uinfo = authUser.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
if(!uinfo.next()) {
	response.setStatus(404);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"사용자 정보가 없습니다.\"}");
	return;
}
if(!isAdmin && !"Y".equals(uinfo.s("tutor_yn"))) {
	response.setStatus(403);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"교수자 권한이 없습니다.\"}");
	return;
}

// -------------------- 프록시 처리 --------------------

// 왜: `/tutor_lms/api/statistics_proxy.jsp/statistics/dashboard.html` 처럼 "pathInfo"로도 호출할 수 있게 합니다.
//     이렇게 하면 원본 통계 화면이 쓰는 쿼리스트링(`?campus=...`)을 그대로 유지할 수 있어 URL 치환이 단순해집니다.
String targetPath = request.getPathInfo();
if(targetPath == null || "".equals(targetPath.trim())) {
	targetPath = m.rs("path").trim();
}
if(targetPath == null || "".equals(targetPath.trim())) {
	response.setStatus(400);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"path(파라미터 또는 pathInfo)가 필요합니다.\"}");
	return;
}
targetPath = targetPath.trim();

// 왜: 오픈 프록시가 되지 않도록 통계 경로만 허용합니다.
if(!targetPath.startsWith("/statistics/")) {
	response.setStatus(400);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"허용되지 않은 path 입니다.\"}");
	return;
}

String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
apiBase = apiBase.replaceAll("/+$", "");

String method = request.getMethod();
if(method == null) method = "GET";
method = method.toUpperCase(Locale.ROOT);

if(!("GET".equals(method) || "POST".equals(method))) {
	response.setStatus(405);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"GET/POST만 허용됩니다.\"}");
	return;
}

String targetUrl = "";
String qs = request.getQueryString();

if(request.getPathInfo() != null && !"".equals(request.getPathInfo().trim())) {
	// 왜: pathInfo로 들어오면 queryString을 그대로 전달해도 안전합니다.
	targetUrl = apiBase + targetPath + (qs != null && !"".equals(qs) ? "?" + qs : "");
} else {
	// 왜: path 파라미터 방식은 path=...를 제외하고 query를 재구성해서 전달합니다.
	StringBuilder rebuilt = new StringBuilder();
	Enumeration<String> paramNames = request.getParameterNames();
	while(paramNames.hasMoreElements()) {
		String name = paramNames.nextElement();
		if("path".equals(name)) continue;
		String[] values = request.getParameterValues(name);
		if(values == null) continue;
		for(int i = 0; i < values.length; i++) {
			String v = values[i];
			if(rebuilt.length() > 0) rebuilt.append("&");
			rebuilt.append(URLEncoder.encode(name, "UTF-8"));
			rebuilt.append("=");
			rebuilt.append(URLEncoder.encode(v == null ? "" : v, "UTF-8"));
		}
	}
	targetUrl = apiBase + targetPath + (rebuilt.length() > 0 ? "?" + rebuilt.toString() : "");
}

HttpURLConnection conn = null;
int httpCode = 0;
try {
	conn = (HttpURLConnection) new URL(targetUrl).openConnection();
	conn.setRequestMethod(method);
	conn.setConnectTimeout(5000);
	conn.setReadTimeout(60000);

	String contentType = request.getContentType();
	if(contentType != null && !"".equals(contentType)) {
		conn.setRequestProperty("Content-Type", contentType);
	}
	String accept = request.getHeader("Accept");
	if(accept != null && !"".equals(accept)) {
		conn.setRequestProperty("Accept", accept);
	}

	// 왜: POST(JSON) 요청 바디를 그대로 전달합니다. (AI 통계 쿼리 등)
	if("POST".equals(method)) {
		conn.setDoOutput(true);
		try(InputStream is = request.getInputStream(); OutputStream os = conn.getOutputStream()) {
			byte[] buf = new byte[8192];
			int len;
			while((len = is.read(buf)) != -1) os.write(buf, 0, len);
		}
	}

	httpCode = conn.getResponseCode();
	response.setStatus(httpCode);

	String upstreamContentType = conn.getContentType();
	if(upstreamContentType != null && !"".equals(upstreamContentType)) {
		response.setContentType(upstreamContentType);
	} else {
		response.setContentType("application/octet-stream");
	}

	String disposition = conn.getHeaderField("Content-Disposition");
	if(disposition != null && !"".equals(disposition)) {
		response.setHeader("Content-Disposition", disposition);
	}

	InputStream upstreamStream = (httpCode >= 200 && httpCode < 300) ? conn.getInputStream() : conn.getErrorStream();
	if(upstreamStream == null) return;

	boolean isHtml = false;
	if(upstreamContentType != null) {
		String ct = upstreamContentType.toLowerCase(Locale.ROOT);
		isHtml = ct.contains("text/html");
	}
	if(!isHtml && targetPath.toLowerCase(Locale.ROOT).endsWith(".html")) {
		isHtml = true;
	}

	if(isHtml) {
		// 왜: 통계 대시보드 HTML은 내부에서 `/statistics/api/*`를 호출합니다.
		//     교수자 페이지에서는 이 경로가 바로 열리지 않으니, 프록시 경로로 치환해서 한 번에 동작하게 합니다.
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		try(InputStream is = upstreamStream) {
			byte[] buf = new byte[8192];
			int len;
			while((len = is.read(buf)) != -1) baos.write(buf, 0, len);
		}

		String html = new String(baos.toByteArray(), StandardCharsets.UTF_8);
		String proxyPrefix = "/tutor_lms/api/statistics_proxy.jsp/statistics/api/";
		String rewritten = html.replace("/statistics/api/", proxyPrefix);

		byte[] outBytes = rewritten.getBytes(StandardCharsets.UTF_8);
		response.setContentType("text/html; charset=utf-8");
		try(OutputStream os = response.getOutputStream()) {
			os.write(outBytes);
		}
	} else {
		try(InputStream is = upstreamStream; OutputStream os = response.getOutputStream()) {
			byte[] buf = new byte[8192];
			int len;
			while((len = is.read(buf)) != -1) os.write(buf, 0, len);
		}
	}
} catch(Exception e) {
	response.reset();
	response.setStatus(502);
	response.setContentType("application/json; charset=utf-8");
	out.print("{\"message\":\"통계 서버 호출 중 오류가 발생했습니다.\"}");
} finally {
	if(conn != null) conn.disconnect();
}

%>
