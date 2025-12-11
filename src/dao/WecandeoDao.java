package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.io.*;
import java.net.URLEncoder;
import java.util.*;

public class WecandeoDao {

	public String videoKey = "";
	public String errCode = null;
	public String errMsg = null;
	private Writer out = null;
	private boolean debug = false;
	private int totalNum = 0;
	private int listNum = 20;
	private int page = 1;

	public WecandeoDao() {

	}
	
	public WecandeoDao(String vkey) {
		this.videoKey = vkey;
	}

	public void setDebug() {
		this.debug = true;
		this.out = null;
	}
	public void setDebug(Writer out) {
		this.debug = true;
		this.out = out;
	}

	protected void setError(String msg) {
		this.errMsg = msg;
		try {
			if(debug == true) {
				if(null != out) out.write("<hr>" + msg + "<hr>\n");
				else Malgn.errorLog(msg);
			}
		} catch(IOException ioe) { Malgn.errorLog( "WecandeoDao.setError() : " + ioe.getMessage(), ioe); }
	}

	public void setListNum(int num) {
		this.listNum = num;
	}
	
	public void setPage(int no) {
		this.page = no;
	}

	public int getTotalNum() {
		return this.totalNum;
	}

	//폴더목록
	public DataSet getFolders() {
		DataSet ret = new DataSet();
		
		Json j = new Json("http://api.wecandeo.com/info/v1/folders.json?key=" + this.videoKey);
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//folderList/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//folderList/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getFolders} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			ret = j.getDataSet("//folderList/list");
		}

		return ret;
	}

	public String getFolderId(DataSet folders, String name) {
		String folderId = "";

		int i = 0;
		while(folders.next()) {
			if(i == 0) folderId = folders.s("folder_id");
			else if("LMS".equals(folders.s("folder_name"))) folderId = folders.s("folder_id");
			if(name != null && name.equals(folders.s("folder_name"))) {
				folderId = folders.s("folder_id");
				break;
			}
			i++;
		}

		return folderId;
	}

	//패키지목록
	public DataSet getPackages() {
		DataSet ret = new DataSet();
		
		Json j = new Json("http://api.wecandeo.com/info/v1/packages.json?key=" + this.videoKey);
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//packageList/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//packageList/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getPackages} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			ret = j.getDataSet("//packageList/packageList");
		}

		return ret;
	}

	public String getPackageId(DataSet packages, String loginId) {
		String packageId = "";

		int i = 0;
		while(packages.next()) {
			if(i == 0) packageId = packages.s("package_id");
			else if("LMS".equals(packages.s("package_name"))) packageId = packages.s("package_id");
			if(loginId != null && loginId.equals(packages.s("package_name"))) {
				packageId = packages.s("package_id");
				break;
			}
			i++;
		}

		return packageId;
	}

	public DataSet getVideos(String packageId, String keyword) {
		DataSet ret = new DataSet();

		StringBuilder sb = new StringBuilder();
		sb.append("http://api.wecandeo.com/info/v1/videos.json?key="); sb.append(this.videoKey);
		sb.append("&pkg="); sb.append(packageId);
		sb.append("&pagesize=" + this.listNum);
		sb.append("&page=" + this.page);
		sb.append("&sort_item=id&sort_direction=desc&pagesize=20000");
		if(!"".equals(keyword)) {
			sb.append("&search_item=title&keyword="); 
			try { sb.append(URLEncoder.encode(keyword, "UTF-8")); }
			catch(UnsupportedEncodingException uee) { Malgn.errorLog( "UnsupportedEncodingException : WecandeoDao.getVideos() : " + uee.getMessage(), uee); }
			catch(Exception e) { Malgn.errorLog( "Exception : WecandeoDao.getVideos() : " + e.getMessage(), e); }
		}

		Json j = new Json(sb.toString());
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//videoInfoList/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//videoInfoList/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getVideos} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			ret = j.getDataSet("//videoInfoList/videoInfoList");
			this.totalNum = j.getInt("//videoInfoList/paging/totalcount");
		}

		return ret;
	}

	public String getPlayUrl(String accessKey) {
		String url = "http://play.wecandeo.com/video/v/?key=" + getOnetimeKey(accessKey);
		return url;
	}

	public String getOnetimeKey(String accessKey) {
		String key = "";

		Json j = new Json("http://api.wecandeo.com/info/auth/accessKey.json?key=" + this.videoKey + "&access_key=" + accessKey + "&expire=30");
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//authVideo/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//authVideo/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getOnetimeKey} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			key = j.getString("//authVideo/accessKey");
		}
		
		return key;
	}

	public DataSet getUploadToken() {
		DataSet ret = new DataSet();
		
		Json j = new Json("http://api.wecandeo.com/web/v4/uploadToken.json?key=" + this.videoKey);
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//uploadInfo/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//uploadInfo/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getUploadToken} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			ret = j.getDataSet("//uploadInfo");
		}

		return ret;
	}

	public DataSet getInfo(String accessKey, String packageId) {
		DataSet ret = new DataSet();
		
		Json j = new Json("http://api.wecandeo.com/info/v1/video/detail.json?key=" + this.videoKey + "&access_key=" + accessKey + "&pkg=" + packageId);
		if(this.debug == true) j.setDebug(this.out);
		this.errCode = j.getString("//videoDetail/errorInfo/errorCode");
		if(!"None".equals(this.errCode)) {
			this.errMsg = j.getString("//videoDetail/errorInfo/errorMessage");
			Malgn.errorLog("{Video.getPackages} videoKey:" + videoKey + ", this.errCode:" + this.errCode + ", this.errMsg:" + this.errMsg);
		} else {
			ret = j.getDataSet("//videoDetail/videoInfo");
		}

		return ret;
	}
	
	public String getDurationString(int sec) {
	
		sec = (int)(sec / 1000);
		int seconds =  sec % 60;
		int hours = (int)(sec / 3600);
		int minutes = (int)((sec - (hours * 3600)) / 60);
		
		String str = "0" + hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
		return str;
	}
}