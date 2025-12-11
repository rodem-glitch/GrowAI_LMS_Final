<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//기본키
String items = m.rs("items");

if("".equals(items)) items = "[ { \"kind\": 1, \"media_content_key\" : \"XXX-MEDIA_CONTENTKEY-XXX\", \"client_user_id\": \"XXXXXXX\", \"player_id\": \"xxxxxxxxxxxxxxxx\", \"device_name\": \"XXXXX\", \"uservalues\": { \"uservalue0\": \"240\", \"uservalue1\": \"value1\" } }, { \"kind\": 2, \"media_content_key\" : \"XXX-MEDIA_CONTENTKEY-XXX\", \"client_user_id\": \"XXXXXXX\", \"player_id\": \"xxxxxxxxxxxxxxxx\", \"device_name\": \"XXXXX\", \"uservalues\": { \"uservalue0\": \"240\" } }, { \"kind\": 3, \"session_key\" : \"XXX-SESSION_KEY-XXX\", \"media_content_key\" : \"XXX-MEDIA_CONTENTKEY-XXX\", \"client_user_id\": \"XXXXXXX\", \"player_id\": \"xxxxxxxxxxxxxxxx\", \"device_name\": \"XXXXX\", \"uservalues\": { \"uservalue1\": \"value1\" } }]";

m.log("drm", "REQUEST : " + items);

CourseUserDao cu = new CourseUserDao();
KollusDao kollus = new KollusDao(siteinfo.s("access_token"), siteinfo.s("security_key"), siteinfo.s("custom_key"));
DataSet ret = new DataSet();

Json j = new Json();
DataSet rs = j.decode(items);
while(rs.next()) {

	if(!"".equals(rs.s("uservalues"))) {
		DataSet val = j.decode(rs.s("uservalues"));
		if(val.next()) {
			rs.put("uservalue0", val.s("uservalue0"));
			rs.put("uservalue1", val.s("uservalue1"));
			rs.put("uservalue2", val.s("uservalue2"));
		}
	} else {
		rs.put("uservalue0", "");
		rs.put("uservalue1", "");
		rs.put("uservalue2", "");
	}

	if(rs.i("kind") == 1) {
		ret.addRow();
		ret.put("kind", 1);
		ret.put("media_content_key", rs.s("media_content_key"));
		//ret.put("expiration_count", 30);
		//ret.put("expiration_playtime", 60);

		int cuid = rs.i("uservalue0");
		DataSet info = cu.find("id = ? AND status = 1", new Object[] { new Integer(cuid) });
		if(info.next()) {
			ret.put("expiration_date", m.getUnixTime(info.s("end_date") + "235959"));
			ret.put("result", 1);
		} else {
			ret.put("result", 0);
			ret.put("message", "수강신청 정보가 없습니다.");
		}

	} else if(rs.i("kind") == 2) {
		ret.addRow();
		ret.put("kind", 2);
		ret.put("media_content_key", rs.s("media_content_key"));
		//ret.put("content_delete", 0);
		ret.put("result", 1);
	} else if(rs.i("kind") == 3) {
		ret.addRow();
		ret.put("kind", 3);
		ret.put("session_key", rs.s("session_key"));
		ret.put("media_content_key", rs.s("media_content_key"));
		ret.put("start_at", rs.i("start_at"));
		//ret.put("content_expired", 0);
		//ret.put("content_delete", 0);
		//ret.put("content_expire_reset", 1);
		//ret.put("expiration_date", 1402444800);
		//ret.put("expiration_count", 10);
		//ret.put("expiration_playtime", 3600);
		ret.put("result", 1);
	}

}

response.setHeader("X-Kollus-UserKey", siteinfo.s("custom_key"));

String res = "{\"data\": " + ret.serialize() + "}";
out.print(kollus.getWebToken(res));

m.log("drm", "RESPONSE : " + res);

%>