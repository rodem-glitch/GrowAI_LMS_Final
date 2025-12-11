package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Hashtable;
import java.util.Set;
import java.util.regex.*;
import org.json.*;

public class KtalkDao extends DataObject {
	
	public String smsId = "";
	public String smsPasswd = "";
	public String senderKey = "";
	
	private int siteId = 0;
	
	private Malgn m = null;
	private Writer out = null;

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] types = { "A=>영리/광고성", "I=>비광고성" };
	public String[] alltypes = { "A=>영리/광고성", "I=>비광고성", "S=>시스템" };

	public String[] statusListMsg = { "1=>list.sms.status_list.1", "0=>list.sms.status_list.0" };
	public String[] typesMsg = { "A=>list.sms.types.A", "I=>list.sms.types.I" };
	public String[] alltypesMsg = { "A=>list.sms.alltypes.A", "I=>list.sms.alltypes.I", "S=>list.sms.alltypes.S" };

	public KtalkDao() {
		this.table = "TB_KTALK";
	}

	public KtalkDao(int siteId) {
		this.table = "TB_KTALK";
		this.siteId = siteId;
	}

	public KtalkDao(String smsId) {
		this.table = "TB_KTALK";
		this.smsId = smsId;
	}

	public void setAccount(String id, String passwd) {
		this.smsId = id;
		this.smsPasswd = passwd;
	}

	public void setAccount(String id, String passwd, String senderKey) {
		this.smsId = id;
		this.smsPasswd = passwd;
		this.senderKey = senderKey;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}
	
	public void setMalgn(Malgn m) {
		this.m = m;
	}
	
	public void setWriter(Writer out) {
		this.out = out;
	}

	public boolean isMobile(String value) {
		Pattern pattern = Pattern.compile("^([0-9]{2,3}-?[0-9]{3,4}-?[0-9]{4})$");
		Matcher match = pattern.matcher(value);
		return match.find();
	}

	public boolean insertKtalk(int siteId, int userId, String sender, String content, DataSet uinfo, String templateCd, String ktalkCode) throws Exception {
		return insertKtalk(siteId, userId, sender, content, uinfo, templateCd, ktalkCode, "I");
	}

	public boolean insertKtalk(int siteId, int userId, String sender, String content, DataSet uinfo, String templateCd, String ktalkCode, String smsType) throws Exception {
		KtalkUserDao ktalkUser = new KtalkUserDao();

		int newId = this.getSequence();
		this.item("id", newId);
		this.item("site_id", siteId);

		this.item("module", "user");
		this.item("module_id", 0);
		this.item("user_id", userId);
		this.item("sms_type", smsType);
		this.item("template_cd", templateCd);
		this.item("ktalk_cd", ktalkCode);
		this.item("sender_key", this.senderKey);
		this.item("sender", sender);
		this.item("content", content);
		this.item("resend_id", 0);
		this.item("send_cnt", 1);
		this.item("fail_cnt", 0);
		this.item("send_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);
		if(!this.insert()) return false;

		ktalkUser.item("ktalk_id", newId);
		ktalkUser.item("mobile", SimpleAES.encrypt(uinfo.s("mobile")));
		ktalkUser.item("user_id", uinfo.i("id"));
		ktalkUser.item("user_nm", uinfo.s("user_nm"));
		ktalkUser.item("send_yn", "Y");
		if(!ktalkUser.insert()) {
			this.delete("id = " + newId + "");
			return false;
		}
		
		return true;
	}

	public String send(String to, String from, String message, String ktalkCd) throws Exception {
		//변수
		JSONObject info = new JSONObject(); //WHOLE MESSAGE
		JSONObject rsinfo = new JSONObject(); //RESEND
		
		JSONObject msgAT = new JSONObject(); //KTALK
		JSONObject msgLMS = new JSONObject(); //KTALK-RESEND
		
		JSONObject msgObjectAT = new JSONObject(); //MESSAGE
		JSONObject msgObjectLMS = new JSONObject(); //MESSAGE-RESEND
		
		//포맷팅
		msgAT.put("message", message);
		msgAT.put("senderkey", this.senderKey);
		msgAT.put("templatecode", ktalkCd);
		msgObjectAT.put("at", msgAT);

		msgLMS.put("message", message);
		msgLMS.put("subject", Malgn.cutString(Malgn.stripTags(Malgn.nl2br(message)), 30));
		msgObjectLMS.put("lms", msgLMS);
		
		rsinfo.put("first", "lms");
		
		info.put("account", smsId);
		info.put("type", "at");
		info.put("from", from);
		info.put("to", to);
		info.put("refkey", "1");
		info.put("resend", rsinfo);
		info.put("content", msgObjectAT);
		info.put("recontent", msgObjectLMS);
		
		//HTTP
		StringBuffer buffer = new StringBuffer();
		String line;
		String result = "";
		String encoding = Config.getEncoding();
		String url = "https://api.bizppurio.com/v2/message";
		String data = info.toString();
		Hashtable<String, String> headers = new Hashtable<String, String>();
		headers.put("Content-Type", "application/json");
		headers.put("Accept-Charset", "UTF-8");
		
		URL u = new URL(url);
		HttpURLConnection conn = (HttpURLConnection)u.openConnection();
		conn.setRequestMethod("POST");
		conn.setUseCaches(false);
		conn.setRequestProperty("User-Agent", "Mozilla/5.0");
		
		//헤더정보가 있을 경우
		Set<String> keys = headers.keySet();
		for(String key : keys) {
			conn.setRequestProperty(key, headers.get(key));
		}
		
		conn.setDoOutput(true);
		//conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		try {
			if(data != null) {
				OutputStreamWriter wr = new OutputStreamWriter(conn.getOutputStream(), encoding);
				wr.write(data);
				wr.flush();
				wr.close();
			}
			int responseCode = conn.getResponseCode();
			
			InputStream is = conn.getInputStream();
			BufferedReader in = new BufferedReader(new InputStreamReader(is, encoding));
			int i = 1;
			while((line = in.readLine()) != null) {
				if(i > 1000) break;
				buffer.append(line + "\r\n");
				i++;
			}
			in.close();
			result = buffer.toString();
		} catch(IOException e) {
			InputStream is = conn.getErrorStream();
			BufferedReader in = new BufferedReader(new InputStreamReader(is, encoding));
			int i = 1;
			while((line = in.readLine()) != null) {
				if(i > 1000) break;
				buffer.append(line + "\r\n");
				i++;
			}
			in.close();
			result = buffer.toString();
		}
		
		if(m != null) {
			m.log("error", info.toString());
			m.log("error", result);
		}
		return result;

	}


	public DataSet getHours() {
		DataSet hours = new DataSet();
		for(int i=0; i<24; i++) {
			hours.addRow();
			hours.put("id", (i < 10 ? "0" : "") + i);
			hours.put("name", (i < 10 ? "0" : "") + i);
		}
		hours.first();
		return hours;
	}
	public DataSet getMinutes() {
		return getMinutes(1);
	}
	public DataSet getMinutes(int step) {
		DataSet minutes = new DataSet();
		for(int i=0; i<60; i+=step) {
			minutes.addRow();
			minutes.put("id", (i < 10 ? "0" : "") + i);
			minutes.put("name", (i < 10 ? "0" : "") + i);
		}
		minutes.first();
		return minutes;
	}

	public String maskMobile(String value) {
		if(!this.isMobile(value)) return value;

		String mobile[] = Malgn.split("-", value);
		return mobile[0] + "-" + Malgn.strpad("", mobile[1].length(), "*") + "-" + mobile[2];
	}
}