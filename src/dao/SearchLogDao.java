package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import javax.servlet.http.HttpServletRequest;

public class SearchLogDao extends DataObject {
	
	private HttpServletRequest request;

	public SearchLogDao() {
		this.table = "TB_SEARCH_LOG";
		this.PK = "id";
	}

	public SearchLogDao(HttpServletRequest request) {
		this.table = "TB_SEARCH_LOG";
		this.PK = "id";
		this.request = request;
	}

	public void setRequest(HttpServletRequest request) {
		this.request = request;
	}
	
	public boolean addLog(int siteId, int userId, String keyword) {
		if(siteId == 0 || "".equals(keyword)) return false;

		String today = Malgn.time("yyyyMMdd");
		String now = Malgn.time("yyyyMMddHHmmss");
		String ipAddr = request.getRemoteAddr();

		if(0 < this.findCount("site_id = " + siteId + " AND user_id = " + userId + " AND keyword = '" + keyword + "' AND ip_addr = '" + ipAddr + "' AND log_date = '" + today + "'")) {
			return true;
		}

		this.item("site_id", siteId);
		this.item("user_id", userId);
		this.item("keyword", keyword);
		this.item("referer", request.getHeader("referer"));
		this.item("ip_addr", ipAddr);
		this.item("request_url", request.getRequestURL().toString());
		this.item("request_uri", request.getRequestURI());
		this.item("request_query", request.getQueryString());
		this.item("agent", request.getHeader("user-agent"));
		this.item("log_date", today);
		this.item("reg_date", now);
		return this.insert();
	}

}