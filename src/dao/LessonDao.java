package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class LessonDao extends DataObject {

	private String apiUrl = "https://chat.malgnlms.com/api/index.php";

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] htmlTypes = { "01=>wecandio", "02=>lesson", "03=>movie", "04=>link", "05=>catenoid", "06=>doczoom", "07=>catenoid", "15=>twoway" };
	public String[] useTypes = { "Y=>활성", "N=>비활성" };
	public String[] chatUseTypes = { "Y=>사용", "N=>중지" };

	public String[] types = { "01=>동영상(위캔디오)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)", "11=>강의", "12=>시험", "13=>실습", "14=>설문", "15=>kt랜선에듀" };
	public String[] types2 = { "01=>동영상(위캔디오)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)", "11=>강의", "12=>시험", "13=>실습", "14=>설문"};
	public String[] catenoidTypes = { "05=>동영상(콜러스)", "07=>라이브(콜러스)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)", "11=>강의", "12=>시험", "13=>실습", "14=>설문", "15=>kt랜선에듀" };
	public String[] catenoidTypes2 = { "05=>동영상(콜러스)", "07=>라이브(콜러스)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)", "11=>강의", "12=>시험", "13=>실습", "14=>설문" };
	public String[] allTypes = { "01=>동영상(위캔디오)", "05=>동영상(콜러스)", "07=>라이브(콜러스)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크","06=>문서(닥줌)", "11=>강의", "12=>시험", "13=>실습", "14=>설문", "15=>kt랜선에듀"};

	public String[] lessonTypes = { "01=>동영상(위캔디오)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)" };
	public String[] catenoidLessonTypes = { "05=>동영상(콜러스)", "07=>라이브(콜러스)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)" };
	public String[] allLessonTypes = { "01=>동영상(위캔디오)", "05=>동영상(콜러스)", "07=>라이브(콜러스)", "02=>웹콘텐츠(WBT)", "03=>MP4", "04=>외부링크", "06=>문서(닥줌)" };

	public String[] offlineTypes = { "11=>강의", "12=>시험", "13=>실습", "14=>설문" };
	public String[] twowayTypes = { "15=>kt랜선에듀" };
	public String[] onoffTypes = { "N=>온라인", "F=>집합", "T=>화상", "B=>혼합", "P=>패키지" };

	public String[] statusListMsg = { "1=>list.lesson.status_list.1", "0=>list.lesson.status_list.0" };
	public String[] useTypesMsg = { "Y=>list.lesson.use_types.Y", "N=>list.lesson.use_types.N" };

	public String[] typesMsg = { "01=>list.lesson.types.01", "02=>list.lesson.types.02", "03=>list.lesson.types.03", "04=>list.lesson.types.04", "06=>list.lesson.types.06", "11=>list.lesson.types.11", "12=>list.lesson.types.12", "13=>list.lesson.types.13", "14=>list.lesson.types.14", "15=>list.lesson.types.15" };
	public String[] catenoidTypesMsg = { "05=>list.lesson.catenoid_types.05", "02=>list.lesson.catenoid_types.02", "03=>list.lesson.catenoid_types.03", "04=>list.lesson.catenoid_types.04", "06=>list.lesson.catenoid_types.06", "11=>list.lesson.catenoid_types.11", "12=>list.lesson.catenoid_types.12", "13=>list.lesson.catenoid_types.13", "14=>list.lesson.catenoid_types.14", "15=>list.lesson.catenoid_types.15" };
	public String[] allTypesMsg = { "01=>list.lesson.all_types.01", "05=>list.lesson.01", "02=>list.lesson.02", "03=>list.lesson.all_types.03", "04=>list.lesson.all_types.04", "06=>list.lesson.all_types.06", "11=>list.lesson.all_types.11", "12=>list.lesson.all_types.12", "13=>list.lesson.all_types.13", "14=>list.lesson.all_types.14", "15=>list.lesson.all_types.15" };

	public String[] lessonTypesMsg = { "01=>list.lesson.lesson_types.01", "02=>list.lesson.lesson_types.02", "03=>list.lesson.lesson_types.03", "04=>list.lesson.lesson_types.04", "06=>list.lesson.lesson_types.06", "15=>list.lesson.lesson_types.15" };
	public String[] catenoidLessonTypesMsg = { "05=>list.lesson.catenoid_lesson_types.05", "07=>list.lesson.catenoid_lesson_types.07", "02=>list.lesson.catenoid_lesson_types.02", "03=>list.lesson.catenoid_lesson_types.03", "04=>list.lesson.catenoid_lesson_types.04", "06=>list.lesson.catenoid_lesson_types.06", "15=>list.lesson.catenoid_lesson_types.15" };
	public String[] allLessonTypesMsg = { "01=>list.lesson.all_lesson_types.01", "05=>list.lesson.all_lesson_types.05", "07=>list.lesson.catenoid_lesson_types.07", "02=>list.lesson.all_lesson_types.02", "03=>list.lesson.all_lesson_types.03", "04=>list.lesson.all_lesson_types.04", "06=>list.lesson.all_lesson_types.06", "15=>list.lesson.all_lesson_types.15" };

	public String[] offlineTypesMsg = { "11=>list.lesson.offline_types.11", "12=>list.lesson.offline_types.12", "13=>list.lesson.offline_types.13", "14=>list.lesson.offline_types.14" };
	public String[] onoffTypesMsg = { "N=>list.lesson.onoff_types.N", "F=>list.lesson.onoff_types.F", "B=>list.lesson.onoff_types.B", "P=>list.lesson.onoff_types.P", "T=>list.lesson.onoff_types.T" };

	public LessonDao() {
		this.table = "LM_LESSON";
	}

	public void setApiUrl(String apiUrl) {
		this.apiUrl = apiUrl;
	}

	public void autoSort(int contentId, int siteId) {
		if(contentId == 0) return;

		DataSet listY = this.find("site_id = " + siteId + " AND content_id = " + contentId + " AND use_yn = 'Y' AND status != -1 ", "id, sort", "sort ASC");
		DataSet listN = this.find("site_id = " + siteId + " AND content_id = " + contentId + " AND use_yn = 'N' AND status != -1 ", "id, sort", "sort ASC");
		
		int sortY = 1;
		int sortN = 1;

		while(listY.next()) {
			this.execute("UPDATE " + this.table + " SET sort = " + sortY + " WHERE id = " + listY.i("id") + " AND use_yn = 'Y' AND status != -1");
			sortY++;
		}
		while(listN.next()) {
			this.execute("UPDATE " + this.table + " SET sort = " + sortN + " WHERE id = " + listN.i("id") + " AND use_yn = 'N' AND status != -1");
			sortN++;
		}
	}
/*
	public int getMaxSort(int cid, String useYn) {
		if(0 == cid || "".equals(useYn)) { return -1; }
		return 1 + this.findCount("content_id = " + cid + " AND use_yn = '" + useYn + "' AND status != -1");
	}
*/
	public int getMaxSort(int cid, String useYn, int siteId) {
		if("".equals(useYn)) { return -1; }
		if("N".equals(useYn)) { return 99999; }
		return 1 + this.findCount("site_id = " + siteId + " AND content_id = " + cid + " AND use_yn = 'Y' AND status != -1");
	}

	private String getSecretKey() {
		DataSet info = Config.getDataSet("//config/privateKey/minitalk");
		info.next();
		return info.s("secretKey");
	}

	public boolean insertChannel(String channelId, String siteName, String title) {
		Http http = new Http(apiUrl);
		http.setHeader("SECRET_KEY", this.getSecretKey());
		http.setParam("api", "channel");
		http.setParam("channel", channelId);
		http.setParam("category1", siteName);
		http.setParam("title", title);
		http.setParam("max_user", "2000");
		http.setParam("box_limit", "9");
		http.setParam("font_limit", "9");
		http.setParam("file_limit", "9");
		http.setParam("guest_name", "GUEST");
		http.setParam("password", "");
		http.setParam("extras", "");

		String jstr = http.send("POST");
		Json j = new Json(jstr);

		boolean success = "true".equals(j.getString("//success"));

		if(!success) Malgn.errorLog("minitalk : " + jstr);

		return success;
	}
	
	public String getChannelId(String ftpId, int siteId, int id, int lid, String type) {
		return ftpId + "s" + siteId + type + id + "l" + lid;
	}

	public String getNickname(String nickname, String userIp) {
		Http http = new Http(apiUrl);
		http.setHeader("SECRET_KEY", this.getSecretKey());
		http.setParam("api", "nickname");
		http.setParam("nickname", nickname);
		http.setParam("level", "1");
		http.setParam("nickcon", "");
		http.setParam("photo", "");
		http.setParam("extras", "");
		http.setParam("userIp", userIp);

		String jstr = http.send("POST");
		Json j = new Json(jstr);

		boolean success = "true".equals(j.getString("//success"));

		if(!success) {
			Malgn.errorLog("nickname : " + jstr);
			return "";
		}

		return j.getString("//message");
	}

/*
	//권한검사
	public boolean accessible(int id, int userId, int siteId) {
		if(id == 0 || userId == 0 || siteId == 0) return false;

		String today = Malgn.time("yyyyMMdd");

		DataSet culist = this.query(
			" SELECT c.restudy_yn, c.restudy_day, cu.end_date "
			+ " FROM " + this.table + " a "
			+ " INNER JOIN " + new CourseLessonDao().table + " cl ON cl.lesson_id = a.id AND cl.status = 1 "
			+ " INNER JOIN " + new CourseUserDao().table + " cu ON cu.course_id = cl.course_id AND cu.user_id = " + userId + " AND cu.status IN (1, 3) "
				+ " AND cu.start_date <= '" + today + "'"
			+ " INNER JOIN " + new CourseDao().table + " c ON c.id = cl.course_id AND c.status = 1 "
			+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status = 1 "
		);
		while(culist.next()) {
			if(0 >= Malgn.diffDate("D", culist.s("end_date"), today)) return true;
			else if(culist.b("restudy_yn") && 0 >= Malgn.diffDate("D", Malgn.addDate("D", culist.i("restudy_day"), culist.s("end_date"), "yyyyMMdd"), today)) return true;
		}
		
		return false;
	}
*/
}
