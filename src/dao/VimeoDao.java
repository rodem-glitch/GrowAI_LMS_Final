package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import org.json.*;
import java.util.*;
import java.io.File;
import java.io.Writer;

public class VimeoDao extends DataObject {

	public String apiUrl = "https://api.vimeo.com";
	public String accessToken = "";
	public String errorCode = null;
	public String errorMessage = null;
	private Writer out = null;
	private boolean debug = false;

	public VimeoDao() {
		this.table = "TB_VIMEO";
		this.PK = "id";
	}
	
	public VimeoDao(String token) {
		this.table = "TB_VIMEO";
		this.PK = "id";
		this.accessToken = token;
	}

	public void setDebug() {
		debug = true;
		this.out = null;
	}
	public void setDebug(Writer out) {
		debug = true;
		this.out = out;
	}
	public void d(Writer out) { setDebug(out); }
	public void d() { setDebug(); }

	public DataSet apiRequest(String endpoint, String method, Map<String, String> params, String path) {
		DataSet res = new DataSet();
		Http http = new Http(apiUrl + endpoint);
		http.setHeader("Content-Type", "application/json");
		http.setHeader("Authorization", "Bearer " + this.accessToken);
		http.setDebug(out);
		if(params != null) {
			for(String key : params.keySet()) {
				http.setParam(key, params.get(key));
			}
		}
		String body = http.send(method);

		Json json = new Json(body);
		res = json.getDataSet(path == null ? "//" : path);
		return res;
	}

	public DataSet getMe() {
		return apiRequest("/me", "GET", null, "//metadata");
	}

	public DataSet getVideos(String query) throws Exception {
		HashMap<String, String> params = null;
		if(!"".equals(query)) {
			params = new HashMap<String, String>();
			params.put("filter", "CC");
			params.put("query", query);
		}
		DataSet list = apiRequest("/me/videos", "GET", params, "//data");
		while(list.next()) {
			String pictures = list.s("pictures");
			JSONObject jo = new JSONObject(pictures);
			JSONArray ja = jo.getJSONArray("sizes");
			JSONObject jao = ja.getJSONObject(0);
			list.put("thumbnail", jao.getString("link"));
		}
		list.first();
		return list;
	}
	
	//폴더목록
	public DataSet getFolders() throws Exception {
		return apiRequest("/videos", "GET", null, null);
		
	}

}