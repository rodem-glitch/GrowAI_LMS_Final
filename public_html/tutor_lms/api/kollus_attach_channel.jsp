<%@ page pageEncoding="utf-8" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ include file="init.jsp" %><%

// 왜 필요한가:
// - Kollus 업로드는 "파일 전송"만으로 끝나지 않고, 채널에 attach(연결)되어야 화면 목록에서 안정적으로 조회됩니다.
// - 프론트엔드에서는 업로드가 끝난 뒤 upload_file_key만 넘기고, 서버가 채널 연결을 대신 수행합니다.

String uploadKey = m.rs("upload_key");

// 왜: 현재 요구사항은 특정 채널(고정)로만 업로드 결과를 모아야 합니다.
//     사용자가 임의 채널로 보내지 못하게 서버에서 채널키를 고정합니다.
String channelKey = !"".equals(siteinfo.s("kollus_channel")) ? siteinfo.s("kollus_channel") : "u8p6y0itgnuaemiy";

if("".equals(uploadKey)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "upload_key가 필요합니다.");
	result.print();
	return;
}

try {
	// 왜: Kollus VOD API 3.0 문서 기준으로 "콘텐츠 연결" 엔드포인트를 사용해야 합니다.
	//     업로드 URL 생성(c-api-kr)으로 업로드한 결과는 아래 API로 채널에 연결합니다.
	//     POST https://c-api-kr.kollus.com/api/channels/{channel_key}/media-contents/{upload_file_key}/attach

	DataSet siteKollus = new SiteDao().find("id = " + siteId, "access_token");
	String accessToken = siteKollus.next() ? siteKollus.s("access_token") : "";
	if("".equals(accessToken)) {
		result.put("rst_code", "5003");
		result.put("rst_message", "Kollus access_token이 설정되어 있지 않습니다. 관리자에게 문의해 주세요.");
		result.print();
		return;
	}

	// 왜: 업로드 직후에는 Kollus 쪽에서 "media content"가 아직 생성되지 않아
	//     attach 호출이 404(media content not found)로 실패하는 경우가 있습니다.
	//     이때는 조금 기다렸다가 재시도하면 성공하는 경우가 있어, 짧은 재시도(최대 약 20초)를 적용합니다.
	int maxTry = 10;
	int waitMs = 2000;
	int responseCode = 0;
	String responseText = "";

	for(int attempt = 1; attempt <= maxTry; attempt++) {
		URL url = new URL(
			"https://c-api-kr.kollus.com/api/channels/"
			+ URLEncoder.encode(channelKey, "UTF-8")
			+ "/media-contents/"
			+ URLEncoder.encode(uploadKey, "UTF-8")
			+ "/attach?access_token="
			+ URLEncoder.encode(accessToken, "UTF-8")
		);
		HttpURLConnection conn = (HttpURLConnection) url.openConnection();
		conn.setRequestMethod("POST");
		conn.setRequestProperty("Accept", "application/json");

		responseCode = conn.getResponseCode();
		InputStream is = responseCode >= 200 && responseCode < 300 ? conn.getInputStream() : conn.getErrorStream();
		StringBuilder responseBody = new StringBuilder();
		if(is != null) {
			BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));
			String line;
			while ((line = br.readLine()) != null) responseBody.append(line);
			br.close();
		}
		conn.disconnect();

		responseText = responseBody.toString();

		// 성공이면 바로 종료
		if (responseCode >= 200 && responseCode < 300) break;

		// 404 + 특정 메시지면 "아직 생성 전" 가능성이 높으니 재시도
		boolean isNotFound = responseCode == 404;
		boolean isMediaNotFoundMsg = responseText != null && -1 < responseText.toLowerCase().indexOf("media content not found");
		if(isNotFound && isMediaNotFoundMsg && attempt < maxTry) {
			try { Thread.sleep(waitMs); } catch(Exception ignore) {}
			continue;
		}

		// 그 외 오류는 재시도하지 않고 종료
		break;
	}

	DataSet attachRes = new DataSet();
	attachRes.addRow();
	attachRes.put("response_code", responseCode);
	attachRes.put("raw_body", responseText);
	attachRes.put("upload_key", uploadKey);
	attachRes.put("channel_key", channelKey);

	// 왜: Kollus 응답 포맷은 환경/버전별로 달라질 수 있어, 실패는 예외로 잡고
	//     성공 시에는 응답 원문(파싱된 DataSet)을 그대로 내려 추후 디버깅에 활용합니다.
	if (responseCode >= 200 && responseCode < 300) {
		result.put("rst_code", "0000");
		result.put("rst_message", "성공");
	} else {
		result.put("rst_code", "5002");
		result.put("rst_message", "Kollus API 오류 (" + responseCode + "): " + responseText);
	}
	result.put("rst_data", attachRes);
	result.print();
} catch(Exception e) {
	result.put("rst_code", "5000");
	result.put("rst_message", "채널 연결 중 오류: " + e.getMessage());
	result.print();
}

%>
