package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import java.io.File;
import javax.servlet.http.HttpServletRequest;

public class FileLogDao extends DataObject {
	
	private HttpServletRequest request;

	public FileLogDao() {
		this.table = "TB_FILE_LOG";
		this.PK = "id";
	}

	public FileLogDao(HttpServletRequest request) {
		this.table = "TB_FILE_LOG";
		this.PK = "id";
		this.request = request;
	}

	public void setRequest(HttpServletRequest request) {
		this.request = request;
	}

	public DataSet file2info(int siteId, File f) {
		return this.file2info(siteId, f, "");
	}

	public DataSet file2info(int siteId, File f, String filename) {
		DataSet info = new DataSet();
		info.addRow();
		info.put("site_id", siteId);
		info.put("filename", filename);
		info.put("realname", f.getName());
		info.put("filesize", (int)f.length());
		info.put("filepath", f.getPath());
		return info;
	}
	
	public boolean addLog(int userId, DataSet info) {
		this.item("site_id", info.i("site_id"));
		this.item("user_id", userId);
		this.item("file_id", info.i("id"));
		this.item("filename", "".equals(info.s("filename")) ? info.s("realname") : info.s("filename"));
		this.item("realname", info.s("realname"));
		this.item("filesize", info.i("filesize"));
		this.item("filepath", info.s("filepath"));
		this.item("referer", request.getHeader("referer"));
		this.item("ip_addr", request.getRemoteAddr());
		this.item("request_url", request.getRequestURL().toString());
		this.item("request_uri", request.getRequestURI());
		this.item("request_query", request.getQueryString());
		this.item("agent", request.getHeader("user-agent"));
		this.item("log_date", Malgn.time("yyyyMMdd"));
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		return this.insert();
	}

	public String getBrowser(String agent) {
		String result = "unknown";
		if(agent == null || "".equals(agent)) return result;

		if(agent.indexOf("MSIE 6.0") > -1) result = "IE6";
		else if (agent.indexOf("MSIE 7.0") > -1) result = "IE7";
		else if (agent.indexOf("MSIE 8.0") > -1) result = "IE8";
		else if (agent.indexOf("MSIE 9.0") > -1) result = "IE9";
		else if (agent.indexOf("MSIE 10.0") > -1) result = "IE10";
		else if (agent.indexOf("MSIE 11.0") > -1) result = "IE11";
		else if (agent.indexOf("MSIE 12.0") > -1) result = "IE12";
		
		else if (agent.indexOf("Trident/4.") > -1) result = "IE8";
		else if (agent.indexOf("Trident/5.") > -1) result = "IE9";
		else if (agent.indexOf("Trident/6.") > -1) result = "IE10";
		else if (agent.indexOf("Trident/7.") > -1) result = "IE11";
		else if (agent.indexOf("Trident/8.") > -1) result = "IE11[Win10]";

		else if (agent.indexOf("Edge") > -1) result = "Edge"; //Chrome보다 위에 위치해야 함

		else if (agent.indexOf("Firefox") > -1) result = "Firefox";
		else if (agent.indexOf("Opera") > -1) result = "Opera";
		else if (agent.indexOf("Chrome") > -1) result = "Chrome";
		else if (agent.indexOf("Safari") > -1) result = "Safari";

		if(agent.indexOf("iPad") > -1) result += " [iPad]";
		else if (agent.indexOf("iPhone") > -1) result += " [iPhone]";
		else if (agent.indexOf("Android") > -1) result += " [Android]";

	  return result;
	}

}