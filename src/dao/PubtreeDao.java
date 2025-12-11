package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import malgnsoft.json.*;
import java.util.*;
import java.io.*;

public class PubtreeDao {

	public String errMsg = null;
	private String pubtreeId;
	private String pubtreePass;
	private String accessToken;
	private Writer out = null;
	private	String host = "https://www.pubtree.net";
	private boolean debug = false;
	private int total = 0;

	private static Hashtable<String, String> tokenMap = new Hashtable<String, String>();

	public PubtreeDao(int siteId) {
		DataSet info = new SiteDao().find("id = " + siteId);
		if(!info.next()) {
			this.pubtreeId = "";
			this.pubtreePass = "";
		}
		this.pubtreeId = info.s("pubtree_id");
		this.pubtreePass = info.s("pubtree_pw");
	}

	public PubtreeDao(String id, String pass) {
		this.pubtreeId = id;
		this.pubtreePass = pass;
	}

	public PubtreeDao(String token) {
		this.accessToken = token;
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
		} catch(IOException ioe) { Malgn.errorLog("PubtreeDao.setError() : " + ioe.getMessage(), ioe); }
	}

	public void setMode(String mode) {
		if("REAL".equals(mode)) this.host = "https://www.pubtree.net";
		else this.host = "http://serv-dev.pubtree.net";
	}

	public String getAccessToken() throws Exception {
		if(this.accessToken != null) return this.accessToken;

		String token = tokenMap.get(this.pubtreeId);
		if(token != null) {
			String[] arr = Malgn.split("|", token);
			if(Long.parseLong(arr[1]) > (Malgn.getUnixTime() * 1000)) return arr[0];
		}
		
		Http http = new Http(this.host + "/login.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setHeader("APPLICATION_VERSION", "1.0");
		http.setHeader("OS", "1.0");
		http.setHeader("DEVICE_IDENTIFIER", "malgnsoft");

		JSONObject obj = new JSONObject();
		obj.put("loginId", this.pubtreeId);
		obj.put("password", this.pubtreePass);

		http.setData(obj.toString());

		Json j = new Json(http.send("POST"));
		DataSet info = j.getDataSet("//result");
		if(info.next()) {
			tokenMap.put(this.pubtreeId, info.s("accessToken") + "|" + info.s("accessTokenExpiredAt"));
			return info.s("accessToken");
		}

		return "";
	}

	public DataSet getContents() throws Exception {
		DataSet list = new DataSet();
		List ids = getIds();
		if(ids == null || ids.size() == 0) return list;

		JSONObject obj = new JSONObject();
		obj.put("contentIds", new JSONArray(ids));

		Http http = new Http(this.host + "/contents/get_contents.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setHeader("APPLICATION_VERSION", "1.0");
		http.setHeader("OS", "1.0");
		http.setHeader("DEVICE_IDENTIFIER", "malgnsoft");
		http.setHeader("ACCESS_TOKEN", getAccessToken());
		http.setData(obj.toString());

		Json j = new Json(http.send("POST"));
		list = j.getDataSet("//result/contents");

		return list;
	}

	public List getIds() throws Exception {
		Http http = new Http(this.host + "/contents/all_ids.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setHeader("APPLICATION_VERSION", "1.0");
		http.setHeader("OS", "1.0");
		http.setHeader("DEVICE_IDENTIFIER", "malgnsoft");
		http.setHeader("ACCESS_TOKEN", getAccessToken());

		String ret = http.send("POST");
		if(this.debug) this.setError(ret);
		
		Json j = new Json(ret);
		DataSet rs = j.getDataSet("//result/archive");

		Vector<String> ids = new Vector<String>();
		for(int i=0; rs.next(); i++) {
			ids.add(rs.s("contentId"));
		}

		return ids;
	}

	public int getTotal() {
		return this.total;
	}

	public DataSet getContentsList(Form f) throws Exception {

		DataSet list = new DataSet();

		Http http = new Http(this.host + "/api/contentsList.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setHeader("APPLICATION_VERSION", "1.0");
		http.setHeader("OS", "1.0");
		http.setHeader("DEVICE_IDENTIFIER", "malgnsoft");
		http.setHeader("ACCESS_TOKEN", getAccessToken());
		http.setParam("page", f.get("page", "1"));
		http.setParam("listRow", f.get("listRow", "20"));
		if(!"".equals(f.get("searchKeywords"))) {
			http.setParam("searchType", f.get("searchType"));
			http.setParam("searchKeywords", f.get("searchKeywords"));
		}
		http.setParam("orderBy", f.get("orderBy", "createDate"));
		http.setParam("orderType", f.get("orderType", "desc"));

		Json j = new Json(http.send("GET"));
		list = j.getDataSet("//result/list");
		DataSet rs = j.getDataSet("//result");
		if(rs.next()) this.total = rs.getInt("total");

		return list;

	}

	public String getDownloadKey(String uuid) throws Exception {
		Http http = new Http(this.host + "/pubtree/getEpubDownloadKey.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setParam("ACCESS_TOKEN", getAccessToken());
		http.setParam("docId", uuid);

		String ret = http.send("GET");
		if(this.debug) this.setError(ret);
		
		DataSet rs = new DataSet();
		Json j = new Json(ret);
		rs = j.getDataSet("//");

		if(rs.next()) return rs.s("returnValue");
		else return "";
	}

	public String getWebViewUrl(String uuid) throws Exception {
		Http http = new Http(this.host + "/pubtree/getWebViewUrl.json");
		if(this.debug) http.setDebug(this.out);
		http.setHeader("Content-Type", "application/json");
		http.setParam("ACCESS_TOKEN", getAccessToken());
		http.setParam("docId", uuid);

		String ret = http.send("GET");
		if(this.debug) this.setError(ret);
		
		DataSet rs = new DataSet();
		Json j = new Json(ret);
		rs = j.getDataSet("//");

		if(rs.next()) return this.host + rs.s("returnValue");
		else return "";
	}

}