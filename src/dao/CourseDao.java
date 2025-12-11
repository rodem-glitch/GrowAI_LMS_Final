package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] taxfreeYn = {"Y=>면세", "N=>과세"};
	public String[] displayYn = { "Y=>보임", "N=>숨김" };
	public String[] saleYn = { "Y=>판매", "N=>중지" };
	public String[] evaluationKeys = { "progress", "exam", "homework", "forum", "etc" };
	public String[] types = { "R=>정규", "A=>상시" };
	public String[] onoffTypes = { "N=>온라인", "F=>집합", "B=>혼합" };
	public String[] onoffPackageTypes = { "N=>온라인", "F=>집합", "B=>혼합", "P=>패키지" };
	public String[] ordList = {
								"id asc=>a.id asc", "id desc=>a.id desc", "rs asc=>a.request_sdate asc", "rs desc=>a.request_sdate desc"
								, "re asc=>a.request_edate asc", "re desc=>a.request_edate desc", "ss asc=>a.study_sdate asc", "ss desc=>a.study_sdate desc"
								, "st asc=>a.sort asc", "st desc=>a.sort desc", "as asc=>a.allsort asc", "as desc=>a.allsort desc"
								, "ry asc=>a.recomm_yn asc", "ry desc=>a.recomm_yn desc"
							};
	public String[] compNoOrderYn = { "Y=>사용", "N=>미사용" };
	public String[] postfixType = { "R=>수강순번", "C=>수강생아이디" };
	public String[] postfixOrd = { "A=>오름차순", "D=>내림차순" };

	public String[] grades = { "H1=>고1", "H2=>고2", "H3=>고3", "M1=>중1", "M2=>중2", "M3=>중3" };
	public String[] terms = { "1=>1학기", "S=>여름학기", "2=>2학기", "W=>겨울학기" };
	public String[] subjects = { "K=>국어", "E=>영어", "M=>수학", "SO=>사회", "SC=>과학" };

	public String[] statusListMsg = { "1=>list.course.status_list.1", "0=>list.course.status_list.0" };
	public String[] taxfreeMsg = {"Y=>list.course.taxfree_yn.Y", "N=>list.course.taxfree_yn.N"};
	public String[] displayYnMsg = { "Y=>list.course.display_yn.Y", "N=>list.course.display_yn.N" };
	public String[] saleYnMsg = { "Y=>list.course.sale_yn.Y", "N=>list.course.sale_yn.N" };
	public String[] typesMsg = { "R=>list.course.types.R", "A=>list.course.types.A" };
	public String[] onoffTypesMsg = { "N=>list.course.onoff_types.N", "F=>list.course.onoff_types.F", "B=>list.course.onoff_types.B" };
	public String[] onoffPackageTypesMsg = { "N=>list.course.onoff_package_types.N", "F=>list.course.onoff_package_types.F", "B=>list.course.onoff_package_types.B", "P=>list.course.onoff_package_types.P" };

	private String requestStart = "";
	private String requestEnd = "";
	private String studyStart = "";
	private String studyEnd = "";
	private int lessonDay = 0;

	public CourseDao() {
		this.table = "LM_COURSE";
	}

	public DataSet getCourseList(int siteId) {
		return getCourseList(siteId, 0, "", "");
	}

	public DataSet getCourseList(int siteId, int userId, String userKind) {
		return getCourseList(siteId, userId, userKind, "");
	}

	public DataSet getCourseList(int siteId, int userId, String userKind, String packageYn) {
		return this.query(
			" SELECT a.id, a.course_nm "
			+ " FROM " + this.table + " a "
			+ ("C".equals(userKind) ? " INNER JOIN " + new CourseManagerDao().table + " cm ON cm.course_id = a.id AND cm.user_id = " + userId : "")
			+ " WHERE a.status != -1 AND a.site_id = " + siteId
			+ ("Y".equals(packageYn) ? " AND a.onoff_type = 'P' " : "")
			+ ("N".equals(packageYn) ? " AND a.onoff_type != 'P' " : "")
			+ " ORDER BY a.course_nm ASC, a.reg_date DESC"
		);
	}

	public void setCopyDate(String requestStart, String requestEnd, String studyStart, String studyEnd, int lessonDay) {
		this.requestStart = Malgn.time("yyyyMMdd", requestStart);
		this.requestEnd = Malgn.time("yyyyMMdd", requestEnd);
		this.studyStart = Malgn.time("yyyyMMdd", studyStart);
		this.studyEnd = Malgn.time("yyyyMMdd", studyEnd);
		this.lessonDay = lessonDay;
	}

	public int copyCourse(int courseId, int year, int step, String courseNm) {
		if(0 == courseId || 0 == year || 0 == step || "".equals(courseNm)) return -1;
		if(("".equals(requestStart) || "".equals(requestEnd) || "".equals(studyStart) || "".equals(studyEnd)) && (0 == lessonDay)) return -1;

		DataSet info = this.find("id = " + courseId + " AND onoff_type != 'P' AND status != -1");
		if(!info.next()) return -1;
		String[] columns = info.getColumns();

		//복사
		int newId = this.getSequence();

		for(int i = 0; i < columns.length; i++) {
			this.item(columns[i], info.s(columns[i]));
		}

		this.item("id", newId);
		this.item("year", year);
		this.item("step", step);
		this.item("course_nm", courseNm);
		this.item("course_file", "");

		if("R".equals(info.s("course_type"))) {
			this.item("request_sdate", requestStart);
			this.item("request_edate", requestEnd);
			this.item("study_sdate", studyStart);
			this.item("study_edate", studyEnd);
		}
		if("A".equals(info.s("course_type"))) {
			this.item("lesson_day", lessonDay);
		}

		this.item("close_yn", "N");
		this.item("display_yn", "N");
		this.item("sale_yn", "N");
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		if(!this.insert()) return -1;

		return newId;
	}

	public boolean copyDetail(DataObject dao, int courseId, int newId) {
		return copyDetail(new DataObject[] { dao }, courseId, newId);
	}

	public boolean copyDetail(DataObject[] dao, int courseId, int newId) {
		if(null == dao || 0 == courseId || 0 == newId) return false;

		for(int i = 0; i < dao.length; i++) {
			DataSet list = dao[i].find("course_id = " + courseId);
			if(1 > list.size()) continue;
			String[] columns = list.getColumns();

			//복사
			while(list.next()) {
				if(-1 < list.i("status")) {
					for(int j = 0; j < columns.length; j++) {
						dao[i].item(columns[j], list.s(columns[j]));
					}
					dao[i].item("course_id", newId);
					if(!dao[i].insert()) return false;
				}
			}
		}
		return true;
	}
}
