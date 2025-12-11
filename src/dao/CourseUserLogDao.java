package dao;

import malgnsoft.db.*;

public class CourseUserLogDao extends DataObject {

	private int siteId = 0;

	public String[] statusList = { "1=>입장", "8=>랜선에듀 입장", "8=>랜선에듀 퇴장" };

	public CourseUserLogDao() {
		this.table = "LM_COURSE_USER_LOG";
		this.PK = "id";
	}

	public CourseUserLogDao(int siteId) {
		this.table = "LM_COURSE_USER_LOG";
		this.PK = "id";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
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
		else if (agent.indexOf("Trident/8.") > -1) result = "IE11/Win10";

		else if (agent.indexOf("Edge") > -1) result = "Edge"; //Chrome보다 위에 위치해야 함
		else if (agent.indexOf("Edg") > -1) result = "Edge Chromium";

		else if (agent.indexOf("Firefox") > -1) result = "Firefox";
		else if (agent.indexOf("Opera") > -1) result = "Opera";
		else if (agent.indexOf("Whale") > -1) result = "Whale";
		else if (agent.indexOf("Chrome") > -1) result = "Chrome";
		else if (agent.indexOf("Safari") > -1) result = "Safari";

		if(agent.indexOf("iPad") > -1) result += "/iPad";
		else if (agent.indexOf("iPhone") > -1) result += "/iPhone";
		else if (agent.indexOf("Android") > -1) result += "/Android";
		else if (agent.indexOf("Macintosh") > -1) result += "/Mac";
		else if (agent.indexOf("Mac OS X") > -1) result += "/Mac";

	  return result;
	}
}