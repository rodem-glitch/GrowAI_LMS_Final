<%@ page pageEncoding="utf-8" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ include file="init.jsp" %><%
// 왜 필요한가:
// - Kollus API 토큰을 프론트엔드에 노출하지 않고, 서버에서 안전하게 관리하기 위함입니다.
// - 프론트엔드에서 업로드 URL 요청 시 이 JSP가 Kollus API를 대신 호출하고 결과를 반환합니다.

// Kollus API 설정
String KOLLUS_API_URL = "https://c-api-kr.kollus.com/api/upload/create-url";

// 왜: 멀티사이트 환경이라 사이트별 access_token을 DB에서 읽어와야 합니다.
DataSet siteKollus = new SiteDao().find("id = " + siteId, "access_token");
String KOLLUS_ACCESS_TOKEN = siteKollus.next() ? siteKollus.s("access_token") : "";

try {
    // 파라미터 수집 (m.rs = request string, m.ri = request int)
    String title = m.rs("title");
    String categoryKey = m.rs("category_key");
    int expireTime = m.ri("expire_time") > 0 ? m.ri("expire_time") : 600;
    int isEncryptionUpload = m.ri("is_encryption_upload");
    int isAudioUpload = m.ri("is_audio_upload");

    if ("".equals(KOLLUS_ACCESS_TOKEN)) {
        result.put("rst_code", "5003");
        result.put("rst_message", "Kollus access_token이 설정되어 있지 않습니다. 관리자에게 문의해 주세요.");
        result.print();
        return;
    }

    // Kollus API 호출
    URL url = new URL(KOLLUS_API_URL + "?access_token=" + KOLLUS_ACCESS_TOKEN);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setRequestProperty("Accept", "application/json");
    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    conn.setDoOutput(true);

    // POST 데이터 구성
    StringBuilder postData = new StringBuilder();
    postData.append("expire_time=").append(expireTime);
    postData.append("&is_encryption_upload=").append(isEncryptionUpload);
    postData.append("&is_audio_upload=").append(isAudioUpload);
    if (!"".equals(title)) {
        postData.append("&title=").append(URLEncoder.encode(title, "UTF-8"));
    }
    if (!"".equals(categoryKey)) {
        postData.append("&category_key=").append(URLEncoder.encode(categoryKey, "UTF-8"));
    }

    // 요청 전송
    OutputStream os = conn.getOutputStream();
    byte[] inputBytes = postData.toString().getBytes("UTF-8");
    os.write(inputBytes, 0, inputBytes.length);
    os.close();

    // 응답 읽기
    int responseCode = conn.getResponseCode();
    InputStream is = responseCode >= 200 && responseCode < 300 
        ? conn.getInputStream() 
        : conn.getErrorStream();
    
    StringBuilder responseBody = new StringBuilder();
    BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));
    String line;
    while ((line = br.readLine()) != null) {
        responseBody.append(line);
    }
    br.close();

    // 왜: Kollus API 응답이 성공인지 확인하고 프론트엔드에 전달합니다.
    if (responseCode >= 200 && responseCode < 300) {
        // Kollus API 응답을 그대로 파싱해서 우리 형식으로 변환
        org.json.JSONObject kollusRes = new org.json.JSONObject(responseBody.toString());
        
        if (kollusRes.has("data") && kollusRes.getJSONObject("data").has("upload_url")) {
            org.json.JSONObject data = kollusRes.getJSONObject("data");
            
            // 왜: DataSet을 사용해야 MalgnSoft의 Json 클래스가 올바르게 직렬화합니다.
            DataSet rstData = new DataSet();
            rstData.addRow();
            rstData.put("upload_url", data.getString("upload_url"));
            if (data.has("upload_file_key")) {
                rstData.put("upload_key", data.getString("upload_file_key"));
            }
            if (data.has("expired_at")) {
                rstData.put("expired_at", data.getLong("expired_at"));
            }
            
            result.put("rst_code", "0000");
            result.put("rst_message", "업로드 URL 생성 성공");
            result.put("rst_data", rstData);
        } else {
            // 예상치 못한 응답 형식
            result.put("rst_code", "5001");
            result.put("rst_message", "Kollus API 응답 형식 오류: " + responseBody.toString());
        }
    } else {
        result.put("rst_code", "5002");
        result.put("rst_message", "Kollus API 오류 (" + responseCode + "): " + responseBody.toString());
    }

    conn.disconnect();

} catch (Exception e) {
    result.put("rst_code", "5000");
    result.put("rst_message", "Kollus API 호출 중 오류: " + e.getMessage());
}

result.print();
%>
