package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseSessionDao extends DataObject {

	private int siteId = 0;

	public CourseSessionDao() {
		this.table = "LM_COURSE_SESSION";
		this.PK = "course_user_id,lesson_id";
	}

	public CourseSessionDao(int siteId) {
		this.table = "LM_COURSE_SESSION";
		this.PK = "course_user_id,lesson_id";
		this.siteId = siteId;
	}

	public boolean verifySession(int cuid, int lid, String sid) {
		if(cuid == 0 || lid == 0 || "".equals(sid)) return false;
	
		DataSet info = this.find("course_user_id = " + cuid + " AND lesson_id = " + lid);
		if(!info.next()) return false;

		if(sid.equals(info.s("session_id"))) return true;
		else return false;
	}

	public boolean verifyOnetime(String otid) {
		if("".equals(otid)) return false;
	
		if(1 > this.findCount("onetime_id = '" + otid + "' AND mod_date >= '" + Malgn.addDate("H", -4, new java.util.Date(), "yyyyMMddHHmmss") + "'")) return false;
		else return true;
	}

	public boolean updateSession(int cuid, int lid, String sid) {
		boolean ret = false;

		this.item("session_id", sid);
		this.item("mod_date", Malgn.time("yyyyMMddHHmmss"));

		if(0 < this.findCount("course_user_id = " + cuid + " AND lesson_id = " + lid)) {
			if(this.update("course_user_id = " + cuid + " AND lesson_id = " + lid)) ret = true;
		} else {
			this.item("course_user_id", cuid);
			this.item("lesson_id", lid);
			this.item("site_id", this.siteId);
			if(this.insert()) ret = true;
		}

		return ret;
	}

	public boolean updateOnetime(int cuid, int lid, String otid) {
		boolean ret = false;

		this.item("onetime_id", otid);
		this.item("mod_date", Malgn.time("yyyyMMddHHmmss"));

		if(0 < this.findCount("course_user_id = " + cuid + " AND lesson_id = " + lid)) {
			if(this.update("course_user_id = " + cuid + " AND lesson_id = " + lid)) ret = true;
		} else {
			this.item("course_user_id", cuid);
			this.item("lesson_id", lid);
			this.item("site_id", this.siteId);
			if(this.insert()) ret = true;
		}

		return ret;
	}
}