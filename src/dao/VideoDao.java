package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import org.json.*;
import java.util.*;

public class VideoDao extends DataObject {

	public String videoKey = "";
	public String errorCode = null;
	public String errorMessage = null;

	public VideoDao() {
		this.table = "TB_VIDEO";
		this.PK = "id";
	}
	
	public VideoDao(String vkey) {
		this.table = "TB_VIDEO";
		this.PK = "id";
		this.videoKey = vkey;
	}
	
	public DataSet json2DataSet(JSONArray jarray) throws Exception {
		DataSet list = new DataSet();
		if(jarray == null) return list;

		for(int i = 0; i < jarray.length(); i++) {
			JSONObject temp = jarray.getJSONObject(i);
			list.addRow();
			list.put("__ord", i + 1);

			Iterator it = temp.keys();
			while(it.hasNext()) {
				String key = (String)it.next();
				String value = !"null".equals(temp.getString(key)) ? temp.getString(key) : "";
				list.put(key, value);	
			}
		}
		
		list.first();
		return list;
	}
	
	public DataSet json2DataSet(JSONObject jo) throws Exception {
		DataSet info = new DataSet();
		if(jo == null) return info;

		info.addRow();
		Iterator it = jo.keys();
		while(it.hasNext()) {
			String key = (String)it.next();
			String value = !"null".equals(jo.getString(key)) ? jo.getString(key) : "";
			info.put(key, value);	
		}
	
		info.first();
		return info;
	}

	
	//폴더목록
	public DataSet getFolders() throws Exception {
		errorCode = null;
		errorMessage = null;
		
		Http http = new Http("http://api.wecandeo.com/info/v1/folders.json");
		http.setParam("key", videoKey);
		String data = http.send();
		
		JSONObject jo = new JSONObject(data);
		JSONObject jdata = jo.getJSONObject("folderList");
		JSONObject jerror = jdata.getJSONObject("errorInfo");

		if(!"None".equals(jerror.getString("errorCode"))) {
			errorCode = jerror.getString("errorCode");
			errorMessage = Malgn.replace(jerror.getString("errorMessage"), "\n", " ");
			Malgn.errorLog("{Video.getFolders} videoKey:" + videoKey + ", result:" + data + ", errorCode:" + errorCode + ", errorMessage:" + errorMessage);
			return null;
		}

		JSONArray jarray = jdata.getJSONArray("list");
		return json2DataSet(jarray);
		
	}

	//패키지목록
	public DataSet getPackages() throws Exception {
		errorCode = null;
		errorMessage = null;
		
		Http http = new Http("http://api.wecandeo.com/info/v1/packages.json");
		http.setParam("key", videoKey);
		String data = http.send();
		
		JSONObject jo = new JSONObject(data);
		JSONObject jdata = jo.getJSONObject("packageList");
		JSONObject jerror = jdata.getJSONObject("errorInfo");

		if(!"None".equals(jerror.getString("errorCode"))) {
			errorCode = jerror.getString("errorCode");
			errorMessage = Malgn.replace(jerror.getString("errorMessage"), "\n", " ");
			Malgn.errorLog("{Video.getPackages} videoKey:" + videoKey + ", result:" + data + ", errorCode:" + errorCode + ", errorMessage:" + errorMessage);
			return null;
		}

		JSONArray jarray = jdata.getJSONArray("packageList");
		return json2DataSet(jarray);
	}
	
	//정보
	public DataSet getInfo(String accessKey, String videoPkg) throws Exception {
		errorCode = null;
		errorMessage = null;
		
		Http http = new Http("http://api.wecandeo.com/info/v1/video/detail.json");
		http.setParam("key", videoKey);
		http.setParam("access_key", accessKey);
		http.setParam("pkg", videoPkg);
		String data = http.send();
		
		JSONObject jo = new JSONObject(data);
		JSONObject jdata = jo.getJSONObject("videoDetail");
		JSONObject jerror = jdata.getJSONObject("errorInfo");

		if(!"None".equals(jerror.getString("errorCode"))) {
			errorCode = jerror.getString("errorCode");
			errorMessage = Malgn.replace(jerror.getString("errorMessage"), "\n", " ");
			return null;
		}
		
		JSONObject jinfo = jdata.getJSONObject("videoInfo");
		return json2DataSet(jinfo);
	}
	
	//썸네일
	public DataSet getThumbnails(String accessKey, String videoPkg) throws Exception {
		errorCode = null;
		errorMessage = null;
		
		Http http = new Http("http://api.wecandeo.com/info/v1/video/detail.json");
		http.setParam("key", videoKey);
		http.setParam("access_key", accessKey);
		http.setParam("pkg", videoPkg);
		String data = http.send();
		
		JSONObject jo = new JSONObject(data);
		JSONObject jdata = jo.getJSONObject("videoDetail");
		JSONObject jerror = jdata.getJSONObject("errorInfo");

		if(!"None".equals(jerror.getString("errorCode"))) {
			errorCode = jerror.getString("errorCode");
			errorMessage = Malgn.replace(jerror.getString("errorMessage"), "\n", " ");
			return null;
		}
		
		JSONArray jarray = jdata.getJSONArray("thumbnails");
		return json2DataSet(jarray);
	}

	//썸네일지정
	public boolean setThumbnail(String accessKey, String seq) throws Exception {
		Http http = new Http("http://api.wecandeo.com/info/v1/video/set/thumbnail.json");
		http.setParam("key", videoKey);
		http.setParam("access_key", accessKey);
		http.setParam("seq", seq);
		String data = http.send();

		JSONObject jo = new JSONObject(data);
		JSONObject jdata = jo.getJSONObject("setThumbnail");
		JSONObject jerror = jdata.getJSONObject("errorInfo");
		
		if(!"None".equals(jerror.getString("errorCode"))) {
			errorCode = jerror.getString("errorCode");
			errorMessage = Malgn.replace(jerror.getString("errorMessage"), "\n", " ");
			return false;
		}
		
		return true;
	}


	public String getDurationString(int sec) {
		if(sec < 0) return "0초";
		
		sec = (int)(sec / 1000);
		int seconds =  sec % 60;
		int hours = (int)(sec / 3600);
		int minutes = (int)((sec - (hours * 3600)) / 60);
		
		String str = "";
		if(hours > 0) str = hours + "시간 ";
		if(minutes > 0) str += minutes + "분 ";
		str += seconds + "초";
		return str;
	}
}