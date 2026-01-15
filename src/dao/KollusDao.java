package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import malgnsoft.json.*;

import java.io.IOException;
import java.util.*;
import java.io.Writer;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.Claims;

public class KollusDao {

	public String errMsg = null;
	private String accessToken;
	private String securityKey;
	private String customKey;
	private String categoryKey = "";
	private Writer out = null;
	private boolean debug = false;
	private int totalNum = 0;
	private int expireTime = 60;
	private String apiVersion = "api";

	public KollusDao(int siteId) {
		DataSet info = new SiteDao().find("id = " + siteId, "access_token, security_key, custom_key");
		if(!info.next()) {
			this.accessToken = "";
			this.securityKey = "";
			this.customKey = "";
		}
		this.accessToken = info.s("access_token");
		this.securityKey = info.s("security_key");
		this.customKey = info.s("custom_key");
	}

	public KollusDao(String accessToken, String securityKey) {
		this.accessToken = accessToken;
		this.securityKey = securityKey;
	}

	public KollusDao(String accessToken, String securityKey, String customKey) {
		this.accessToken = accessToken;
		this.securityKey = securityKey;
		this.customKey = customKey;
	}

	public void setDebug() {
		this.debug = true;
		this.out = null;
	}
	public void setDebug(Writer out) {
		this.debug = true;
		this.out = out;
	}
	public void d(Writer out) { setDebug(out); }
	public void d() { setDebug(); }

	protected void setError(String msg) {
		this.errMsg = msg;
		try {
			if(debug == true) {
				if(null != out) out.write("<hr>" + msg + "<hr>\n");
				else Malgn.errorLog(msg);
			}
		}
		catch(IOException ioe) { Malgn.errorLog( "IOException : KollusDao.setError() : " + ioe.getMessage(), ioe); }
		catch(Exception ex) { Malgn.errorLog( "Exception : KollusDao.setError() : " + ex.getMessage(), ex); }
	}
	
	public void setExpireTime(int expireTime) {
		this.expireTime = expireTime;
	}

	public void setApiVersion(String apiVersion) {
		this.apiVersion = apiVersion;
	}

	public void setCategoryKey(String categoryKey) {
		this.categoryKey = categoryKey;
	}

	public String getAccessToken() {
		return this.accessToken;
	}

	public String getSecurityKey() {
		return this.securityKey;
	}

	//영상노출위에 미디어토큰값얻어오기
	public String getMediaToken(String mediaKey, String userId) throws Exception {
		if("".equals(this.accessToken) || "".equals(this.securityKey) || "".equals(mediaKey)) return "";
		String token = "";
		String body = "";
		try {
			Http http = new Http("https://api.kr.kollus.com/0/media_auth/media_token/get_media_link_by_userid");
			http.setParam("security_key", this.securityKey);
			http.setParam("media_content_key", mediaKey);
			http.setParam("access_token", this.accessToken);
			http.setParam("client_user_id", userId);
			http.setParam("expire_time", this.expireTime + "");
			http.setParam("awt_code", "");
			body = http.send("POST");
			
			if(!"".equals(body)) {
				JSONObject json = new JSONObject(body);
				token = (String)((JSONObject) json.get("result")).get("media_token");
			}
		}
		catch(NullPointerException npe) {
			Malgn.errorLog("NullPointerException : KollusDao.getMediaToken, " + mediaKey + ", " + userId + ", " + body, npe);
		}
		catch(Exception e) {
			Malgn.errorLog("Exception : KollusDao.getMediaToken, " + mediaKey + ", " + userId + ", " + body, e);
		}
		return token;
	}

	public String getPlayUrl(String mediaKey, String userId) throws Exception {
		return getPlayUrl(mediaKey, userId, true, true, -1);
	}

	public String getPlayUrl(String mediaKey, String userId, boolean isCompleted, int seekableEnd) throws Exception {
		return getPlayUrl(mediaKey, userId, isCompleted, true, seekableEnd);
	}

	public String getPlayUrl(String mediaKey, String userId, boolean isCompleted, boolean usePlayRate, int seekableEnd) throws Exception {
		String disableSeekScript = (!isCompleted ? String.format(", \"seek\": false, \"seekable_end\": %d", seekableEnd) : "");
		String disablePlayRate = ", \"disable_playrate\": " + (usePlayRate ? "false" : "true");
		String vwcScript = "";
		/*
		String vwcScript = ", \"video_watermarking_code_policy\": {"
			+ "\"code_kind\":\"client_user_id\""
			+ ", \"font_size\":30"
			+ ", \"font_color\":\"FF0000\""
			+ ", \"show_time\":\"1\""
			+ ", \"hide_time\":\"60000\""
			+ ", \"alpha\":255"
			+ ", \"enable_html5_player\":true"
		+ "}";
		*/
		String json = String.format("{\"cuid\": \"%s\"" + vwcScript + ", \"expt\": %d, \"mc\": [{\"mckey\": \"%s\"" + disableSeekScript + disablePlayRate + "}]}", userId, (Malgn.getUnixTime() + this.expireTime), mediaKey);
		if(out != null) {
			out.write(json);
			out.write("\n");
		}
		return "https://v.kr.kollus.com/s?jwt=" + getWebToken(json) + "&custom_key=" + this.customKey;
	}

	public String getLiveUrl(String mediaKey, String userId) throws Exception {
		String json = "{\"client_user_id\": \"" + userId + "\","
			+ "\"video_watermarking_code_policy\": {"
				+ "\"code_kind\":\"client_user_id\","
				+ "\"font_size\":7,"
				+ "\"font_color\":\"FFFFFF\","
				+ "\"show_time\":1,"
				+ "\"hide_time\":500,"
				+ "\"alpha\":50,"
				+ "\"enable_html5_player\": false"
			+ "},"
			+ "\"expire_time\": " + Malgn.getUnixTime() + this.expireTime + ","
			+ "\"live_media_channel_key\": \"" + mediaKey + "\"}";

		if(out != null) {
			out.write(json);
			out.write("\n");
		}
		return "https://v-live-kr.kollus.com/s?jwt=" + getWebToken(json);
	}

	public String getWebToken(HashMap<String, Object> payload) throws Exception {
		return Jwts.builder().setHeaderParam("typ", "JWT").setPayload(Json.encode(payload)).signWith(SignatureAlgorithm.HS256, this.securityKey.getBytes("UTF-8")).compact();
	}

	public String getWebToken(String payload) throws Exception {
		return Jwts.builder().setHeaderParam("typ", "JWT").setPayload(payload).signWith(SignatureAlgorithm.HS256, this.securityKey.getBytes("UTF-8")).compact();
	}
	
	public String getKollusEncrypt(String source) throws Exception {
		if("".equals(this.accessToken) || "".equals(this.securityKey) || "".equals(source)) return "";
		String enc = "";
		try {
			Http http = new Http("https://api.kr.kollus.com/0/media_auth/media_token/get_kollus_encrypt.json");
			http.setParam("security_key", this.securityKey);
			http.setParam("access_token", this.accessToken);
			http.setParam("source_string", source);
			String body = http.send("POST");

			JSONObject json = new JSONObject(body);
			enc = (String)((JSONObject)json.get("result")).get("encrypt_string");
		}
		catch(NullPointerException npe) {
			Malgn.errorLog("NullPointerException : KollusDao.getKollusEncrypt, " + source, npe);
		}
		catch(Exception e) {
			Malgn.errorLog("Exception : KollusDao.getKollusEncrypt, " + source, e);
		}
		return enc;
	}

	//채널목록
	public DataSet getChannels() throws Exception {
		if("".equals(this.accessToken)) return null;

		DataSet channels = new DataSet();
		Json j = new Json("https://api.kr.kollus.com/0/media/channel/index?access_token=" + this.accessToken);
		if(this.debug == true) j.setDebug(this.out);
		if(j.getInt("//error") == 0 && j.getInt("//result/count") > 0) channels = j.getDataSet("//result/items/item");
		return channels;
	}

	public String getChannelKey(DataSet channels, String name) {
		if(channels == null) return "";
		String key = "";
		channels.first();
		while(channels.next()) {
			if(name == null && channels.i("position") == 1) {
				key = channels.s("key");
				break;
			}
			if(channels.s("name").equals(name)) {
				key = channels.s("key");
				break;
			}
		}
		return key;
	}

	public boolean addChannel(String name) {
		try {
			Http http = new Http("https://api.kr.kollus.com/0/media/channel/create?access_token=" + this.accessToken);
			http.setParam("name", name);
			http.setParam("is_encrypted", "0");
			http.setParam("is_shared", "1");
			String body = http.send("POST");

			JSONObject json = new JSONObject(body);
			if(json.getInt("//error") != 0) {
				this.setError(json.getString("message"));
				Malgn.errorLog("KollusDao.addChannel: token:" + this.accessToken + ", name:" + name + ", message:" + json.getString("message"));
				return false;
			}
		}
		catch(NullPointerException npe) {
			this.setError(npe.getMessage());
			Malgn.errorLog("NullPointerException : KollusDao.addChannel: token:" + this.accessToken + ", name:" + name, npe);
			return false;
		}
		catch(Exception e) {
			this.setError(e.getMessage());
			Malgn.errorLog("Exception : KollusDao.addChannel: token:" + this.accessToken + ", name:" + name, e);
			return false;
		}
		return true;
	}

	public DataSet getCategories() throws Exception {
		if("".equals(this.accessToken)) return null;

		DataSet categories = new DataSet();
		Json j = new Json("https://api.kr.kollus.com/0/media/category/index?access_token=" + this.accessToken);
		if(this.debug == true) j.setDebug(this.out);
		if(j.getInt("//error") == 0 && j.getInt("//result/count") > 0) categories = j.getDataSet("//result/items/item");
		return categories;
	}

	public String getCategoryKey(DataSet categories, String name) {
		String key = "";
		categories.first();
		for(int i=0; categories.next(); i++) {
			if(name == null && i == 0) {
				key = categories.s("key");
				break;
			}
			if(categories.s("name").equals(name)) {
				key = categories.s("key");
				break;
			}
		}
		return key;
	}

	public boolean addCategory(String name) {
		String body = "";
		try {
			Http http = new Http("https://api.kr.kollus.com/0/media/category/create?access_token=" + this.accessToken);
			http.setParam("name", name);
			body = http.send("POST");
		}
		catch(NullPointerException npe) {
			this.setError(npe.getMessage());
			Malgn.errorLog("NullPointerException : KollusDao.addCategory: token:" + this.accessToken + ", name:" + name, npe);
			return false;			
		}
		catch(Exception e) {
			this.setError(e.getMessage());
			Malgn.errorLog("Exception : KollusDao.addCategory: token:" + this.accessToken + ", name:" + name, e);
			return false;
		}

		JSONObject json = new JSONObject(body);
		try {
			if(json.getInt("//error") != 0) {
				this.setError(json.getString("message"));
				Malgn.errorLog("KollusDao.addCategory: token:" + this.accessToken + ", name:" + name + ", message:" + json.getString("message"));
				return false;
			}
		}
		catch(NullPointerException npe) { Malgn.errorLog( "KollusDao.addCategory() : " + npe.getMessage(), npe); }
		catch(Exception e) { Malgn.errorLog( "KollusDao.addCategory() : " + e.getMessage(), e); }
		return true;
	}

	public boolean mappingCategory(String categoryKey, String channelKey) {
		if("".equals(categoryKey) || "".equals(channelKey)) return false;

		String body = "";
		try {
			Http http = new Http("https://api-vod-kr.kollus.com/api/v0/vod/channel-mapping/" + categoryKey + "/attach/" + channelKey + "?access_token=" + this.accessToken);
			body = http.send("GET");
		} catch(NullPointerException npe) {
			this.setError(npe.getMessage());
			Malgn.errorLog("KollusDao.mappingCategory: token:" + this.accessToken + ", categoryKey:" + categoryKey + ", channelKey:" + channelKey, npe);
			return false;
		}
		return true;
	}

	// 동영상업로드전에 일회성 업로드 url 을 받아와야한다.
	// isEncrypt : 암호화 true, 비암호화 false, isAudio : 오디오형식true, 동영상형식 false
	public String getUploadUrl(String categoryKey, int isEncrypt) throws Exception {
		if("".equals(this.accessToken)) return null;

		Http http = new Http("https://api.kr.kollus.com/0/media_auth/upload/create_url.json?access_token=" + this.accessToken);
		//http.setParam("access_token", accessToken);
		http.setParam("category_key", categoryKey);
		http.setParam("is_encryption_upload", "" + isEncrypt);
		String body = http.send("POST");

		return body;
	}

	//채널당 콘텐츠목록
	public DataSet getContents(String channel) throws Exception {
		return getContents(channel, "", 1, 20);
	}

	public DataSet getContents(String channel, int ln) throws Exception {
		return getContents(channel, "", 1, ln);
	}

	public DataSet getContents(String channel, String keyword) throws Exception {
		return getContents(channel, keyword, 1, 20);
	}

	public DataSet getContents(String channel, String keyword, int page) throws Exception {
		return getContents(channel, keyword, page, 20);
	}

	public DataSet getContents(String channel, String keyword, int page, int ln) throws Exception {
		DataSet list = new DataSet();
		if("".equals(this.accessToken) || "".equals(channel)) return list;

		StringBuilder sb = new StringBuilder();
		Json json = new Json();
		if(this.debug == true) json.setDebug(this.out);

		
		sb.append("&access_token="); sb.append(this.accessToken);
		sb.append("&page="); sb.append(page);
		sb.append("&per_page="); sb.append(ln);
		if(!"".equals(keyword)) sb.append("&keyword="); sb.append(Malgn.urlencode(keyword));


		if("api-vod".equals(this.apiVersion)) {
			if(!"".equals(this.categoryKey)) sb.append("&category_key="); sb.append(this.categoryKey);
			sb.append("&order_by=created_at_desc");

			json.setUrl("https://api-vod-kr.kollus.com/api/v0/vod/channels/" + channel + "/media-contents?" + sb.toString());
			list = json.getDataSet("//data");
			this.totalNum = list.size();

		} else {
			sb.append("&channel_key="); sb.append(channel);
			sb.append("&order=position_desc");

			json.setUrl("https://api.kr.kollus.com/0/media/channel/media_content?" + sb.toString());
			this.totalNum = json.getInt("//result/count");
			if(0 < this.totalNum) list = json.getDataSet("//result/items/item");
		}

		return list;
	}

	public DataSet getCategoryContents(String category, String keyword, int page) throws Exception {
		return getCategoryContents(category, keyword, page, 20);
	}

	public DataSet getCategoryContents(String category, String keyword, int page, int ln) throws Exception {
		DataSet list = new DataSet();
		if("".equals(this.accessToken) || "".equals(category)) return list;

		Vector<String> v = new Vector<String>();
		v.add("access_token=" + this.accessToken);
		v.add("category_key=" + category);
		v.add("keyword=" + Malgn.urlencode(keyword));
		v.add("page=" + page);
		v.add("per_page=" + ln);
		v.add("order=created_at_desc");

		Json json = new Json();
		if(this.debug == true) json.setDebug(this.out);
		json.setUrl("https://api.kr.kollus.com/0/media/library/media_content?" + Malgn.join("&", v.toArray()));
		this.totalNum = json.getInt("//result/count");
		if(0 < this.totalNum) list = json.getDataSet("//result/items/item");
		return list;
	}

	public int getTotalNum() {
		return this.totalNum;
	}

	public DataSet getContentInfo(String uploadFileKey) throws Exception {
		DataSet info = new DataSet();
		if("".equals(this.accessToken) || "".equals(uploadFileKey)) return info;

		Json json = new Json();
		if(this.debug == true) json.setDebug(this.out);
		json.setUrl("https://api.kr.kollus.com/0/media/library/media_content/" + uploadFileKey + ".json?access_token=" + this.accessToken);
		info = json.getDataSet("//result/item");
		return info;
	}

	//콘텐츠 채널로 이동
	public DataSet moveContent(String channel, String uploadKey) throws Exception  {
		if("".equals(this.accessToken) || "".equals(channel) || "".equals(uploadKey)) return null;

		Http http = new Http("https://api.kr.kollus.com/0/media/channel/attach/" + uploadKey + "?access_token=" + this.accessToken);
		http.setParam("channel_key", channel);
		String body = http.send("POST");

		// 왜: 환경/에러 상황에 따라 Kollus API 응답이 빈 문자열이거나 JSON이 아닐 수 있습니다.
		//     이때 Json 파서가 내부에서 NumberFormatException 등을 발생시키며 전체 업로드 흐름을 깨뜨릴 수 있어,
		//     "파싱 실패"는 안전하게 흡수하고 원문을 돌려 디버깅 가능하게 합니다.
		if(body == null) body = "";
		body = body.trim();

		DataSet data = new DataSet();
		if("".equals(body)) {
			data.addRow();
			data.put("raw_body", "");
			data.put("empty_body", "Y");
			return data;
		}

		try {
			Json json = new Json(body);
			return json.getDataSet("//");
		}
		catch(Exception e) {
			data.addRow();
			data.put("raw_body", body);
			data.put("parse_error", e.getMessage());
			return data;
		}
	}

}
