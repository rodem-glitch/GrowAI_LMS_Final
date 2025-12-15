package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

/**
 * 다중 영상 차시용 서브영상 진도 DAO
 *
 * 왜 이 DAO가 필요한가?
 *  - 기존 LM_COURSE_PROGRESS(차시 단위) 구조를 깨지 않고,
 *    서브영상별 학습시간을 따로 저장한 뒤 합산하여 부모 차시 진도를 갱신하기 위해서입니다.
 *  - 상용 서버에서 기존 단일차시 로직에 영향이 없도록 “분기 처리”만 추가합니다.
 */
public class CourseProgressVideoDao extends DataObject {

	private int siteId = 0;
	private int studyTime = 0; //초 단위 누적(플레이어에서 넘어오는 값)
	private int currTime = 0;  //현재 재생 위치(초)

	public CourseProgressVideoDao() {
		this.table = "LM_COURSE_PROGRESS_VIDEO";
		this.PK = "course_user_id,lesson_id,video_id";
	}

	public CourseProgressVideoDao(int siteId) {
		this.table = "LM_COURSE_PROGRESS_VIDEO";
		this.PK = "course_user_id,lesson_id,video_id";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
	}

	public void setStudyTime(int time) {
		if(time > 0) this.studyTime = time;
	}

	public void setCurrTime(int time) {
		if(time > 0) this.currTime = time;
	}

	/**
	 * 서브영상 진도를 저장하고, 합산 결과로 부모 차시 진도를 갱신합니다.
	 *
	 * @return 2: 부모 차시가 새로 완료됨, 1: 저장만 됨, 음수: 제한/오류
	 */
	public int updateVideoProgress(int cuid, int parentLid, int videoId, int chapter) {

		CourseDao course = new CourseDao();
		CourseLessonDao courseLesson = new CourseLessonDao();
		CourseUserDao courseUser = new CourseUserDao();
		LessonDao lesson = new LessonDao();
		CourseLessonVideoDao clv = new CourseLessonVideoDao();

		//수강생정보
		DataSet cuinfo = courseUser.query(
			// 왜 a.id를 같이 조회하나요?
			// - 아래 updateParentProgress()에서 부모(차시) 진도 갱신 시 course_user_id가 필요합니다.
			// - SELECT에 a.id가 없으면 0으로 처리되어, 부모 진도가 잘못 갱신될 수 있습니다.
			" SELECT a.id, a.course_id, a.user_id, a.end_date, c.period_yn "
			+ " FROM " + courseUser.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
			+ " WHERE a.id = " + cuid + " AND a.status IN (1, 3) "
		);
		if(!cuinfo.next()) return -1;

		//제한-학습종료일일 경우 진도 저장하지 않음
		if(0 < Malgn.diffDate("D", cuinfo.s("end_date"), Malgn.time("yyyyMMdd"))) return -2;

		//제한-차시별학습기간 체크(부모 차시 기준)
		if("Y".equals(cuinfo.s("period_yn"))) {
			DataSet clinfo = courseLesson.find(
				"course_id = ? AND lesson_id = ? AND chapter = ?",
				new Integer[] {cuinfo.i("course_id"), parentLid, chapter},
				"start_date, end_date, start_time, end_time"
			);
			if(!clinfo.next()) return -7;

			String startDateTime = clinfo.s("start_date") + (clinfo.s("start_time").length() == 6 ? clinfo.s("start_time") : "000000");
			String endDateTime = clinfo.s("end_date") + (clinfo.s("end_time").length() == 6 ? clinfo.s("end_time") : "235959");
			String now = Malgn.time("yyyyMMddHHmmss");

			if(0 > Malgn.diffDate("S", startDateTime, now)) return -8;
			else if(0 < Malgn.diffDate("S", endDateTime, now)) return -9;
		}

		//부모 차시가 과정에 실제로 포함된 상태인지 체크
		if(0 == courseLesson.findCount(
			"course_id = " + cuinfo.i("course_id") + " AND lesson_id = " + parentLid + " AND status = 1"
		)) return -3;

		//서브영상 정보
		DataSet vinfo = lesson.find("id = " + videoId + " AND status = 1", "lesson_type, total_time, complete_time");
		if(!vinfo.next()) return -3;
		vinfo.put("total_time", vinfo.i("total_time") * 60);
		vinfo.put("complete_time", vinfo.i("complete_time") * 60);

		//부모 차시 타입(표시/로그용) - 없으면 서브영상 타입으로 대체
		String parentType = vinfo.s("lesson_type");
		DataSet pinfo = lesson.find("id = " + parentLid + " AND status = 1", "lesson_type");
		if(pinfo.next() && !"".equals(pinfo.s("lesson_type"))) parentType = pinfo.s("lesson_type");

		//서브영상 진도 저장
		boolean exists = false;
		int viewCnt = 1;
		int lastTime = 0;
		int studyTimeSec = this.studyTime;
		String completeYN = "N";
		String preCompleteYN = "N";

		DataSet cpvinfo = this.find(
			"course_user_id = " + cuid + " AND lesson_id = " + parentLid + " AND video_id = " + videoId + " AND status = 1",
			"study_time, last_time, view_cnt, complete_yn, complete_date, reg_date"
		);
		if(cpvinfo.next()) {
			exists = true;
			viewCnt += cpvinfo.i("view_cnt");
			preCompleteYN = cpvinfo.s("complete_yn");
			lastTime = currTime > cpvinfo.i("last_time") ? currTime : cpvinfo.i("last_time");
			studyTimeSec = cpvinfo.i("study_time") + studyTimeSec;
		} else {
			lastTime = currTime;
		}

		//진도율 계산(서브영상은 동영상 타입만 사용한다는 전제)
		double ratio = 100.0;
		if(vinfo.i("complete_time") == 0) {
			ratio = 100.0;
			completeYN = "Y";
		} else {
			int ratioTime = Math.min(studyTimeSec, lastTime);
			if(vinfo.i("total_time") > 0 && ratioTime < vinfo.i("complete_time")) {
				ratio = Math.min(100.0, (ratioTime / vinfo.d("total_time")) * 100);
			}
			if(ratioTime >= vinfo.i("complete_time") || ratio >= 100.0) completeYN = "Y";
		}

		this.item("course_id", cuinfo.i("course_id"));
		this.item("lesson_id", parentLid);
		this.item("video_id", videoId);
		this.item("chapter", chapter);
		this.item("course_user_id", cuid);
		this.item("user_id", cuinfo.i("user_id"));
		this.item("lesson_type", vinfo.s("lesson_type"));
		this.item("study_page", 0);
		this.item("study_time", studyTimeSec);
		this.item("curr_page", "");
		this.item("curr_time", currTime);
		this.item("last_time", lastTime);
		this.item("paragraph", "");
		this.item("ratio", ratio);
		this.item("view_cnt", viewCnt);
		this.item("last_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);
		this.item("site_id", siteId);

		if("Y".equals(completeYN)) {
			this.item("ratio", 100.0);
			this.item("complete_yn", "Y");
			if("N".equals(preCompleteYN)) this.item("complete_date", Malgn.time("yyyyMMddHHmmss"));
		} else {
			this.item("complete_yn", "N");
		}

		if(exists) {
			if(!this.update("course_user_id = " + cuid + " AND lesson_id = " + parentLid + " AND video_id = " + videoId)) return -4;
		} else {
			this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
			if(!this.insert()) return -5;
		}

		//부모 차시 진도 합산/갱신
		return updateParentProgress(cuinfo, parentLid, chapter, parentType, clv);
	}

	/**
	 * 서브영상 진도를 합산해서 부모 차시 LM_COURSE_PROGRESS를 갱신합니다.
	 * - 합산 기준: 서브영상 study_time/last_time/complete_time/total_time
	 */
	private int updateParentProgress(DataSet cuinfo, int parentLid, int chapter, String parentType, CourseLessonVideoDao clv) {

		CourseLessonDao courseLesson = new CourseLessonDao();
		LessonDao lesson = new LessonDao();
		CourseProgressDao cp = new CourseProgressDao(siteId);

		//부모 차시의 다중영상 합산 시간(분) 조회
		DataSet clinfo = courseLesson.find(
			"course_id = " + cuinfo.i("course_id") + " AND lesson_id = " + parentLid + " AND status != -1",
			"multi_yn, multi_total_time, multi_complete_time"
		);
		int totalMin = 0;
		int completeMin = 0;
		if(clinfo.next() && "Y".equals(clinfo.s("multi_yn"))) {
			totalMin = clinfo.i("multi_total_time");
			completeMin = clinfo.i("multi_complete_time");
		}

		//캐시가 비어있으면(혹시 모를 운영 실수 대비) 매핑 기준으로 다시 계산
		if(totalMin == 0 && completeMin == 0) {
			DataSet tinfo = clv.query(
				"SELECT SUM(l.total_time) total_time, SUM(l.complete_time) complete_time "
				+ " FROM " + clv.table + " v "
				+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
				+ " WHERE v.course_id = " + cuinfo.i("course_id")
				+ " AND v.lesson_id = " + parentLid
				+ " AND v.status = 1"
			);
			if(tinfo.next()) {
				totalMin = tinfo.i("total_time");
				completeMin = tinfo.i("complete_time");
			}
		}

		int totalSec = totalMin * 60;
		int completeSec = completeMin * 60;

		//부모 차시 학습시간 합산(초) / 진도율 계산용 합산(초)
		int sumStudySec = this.getOneInt(
			"SELECT IFNULL(SUM(study_time),0) FROM " + this.table
			+ " WHERE course_user_id = " + cuinfo.i("id")
			+ " AND lesson_id = " + parentLid
			+ " AND status = 1"
		);
		int sumRatioTimeSec = this.getOneInt(
			"SELECT IFNULL(SUM(LEAST(study_time, last_time)),0) FROM " + this.table
			+ " WHERE course_user_id = " + cuinfo.i("id")
			+ " AND lesson_id = " + parentLid
			+ " AND status = 1"
		);

		//기존 부모 진도 조회
		boolean pExists = false;
		String pPreCompleteYN = "N";
		String pCompleteYN = "N";
		int pViewCnt = 1;

		DataSet pprog = cp.find(
			"course_user_id = " + cuinfo.i("id") + " AND lesson_id = " + parentLid + " AND status = 1",
			"view_cnt, complete_yn, complete_date, reg_date"
		);
		if(pprog.next()) {
			pExists = true;
			pViewCnt += pprog.i("view_cnt");
			pPreCompleteYN = pprog.s("complete_yn");
		}

		//부모 진도율/완료 계산
		double pRatio = 100.0;
		if(completeSec == 0) {
			pRatio = 100.0;
			pCompleteYN = "Y";
		} else {
			if(totalSec > 0 && sumRatioTimeSec < completeSec) {
				pRatio = Math.min(100.0, (sumRatioTimeSec / (double)totalSec) * 100);
			}
			if(sumRatioTimeSec >= completeSec || pRatio >= 100.0) pCompleteYN = "Y";
		}

		//부모 진도 저장(기존 LM_COURSE_PROGRESS 유지)
		cp.item("course_id", cuinfo.i("course_id"));
		cp.item("lesson_id", parentLid);
		cp.item("chapter", chapter);
		cp.item("course_user_id", cuinfo.i("id"));
		cp.item("user_id", cuinfo.i("user_id"));
		cp.item("lesson_type", parentType);
		cp.item("study_page", 0);
		cp.item("study_time", sumStudySec);
		cp.item("curr_page", "");
		cp.item("curr_time", 0);
		cp.item("last_time", sumRatioTimeSec);
		cp.item("paragraph", "");
		cp.item("ratio", pRatio);
		cp.item("view_cnt", pViewCnt);
		cp.item("last_date", Malgn.time("yyyyMMddHHmmss"));
		cp.item("status", 1);
		cp.item("site_id", siteId);

		if("Y".equals(pCompleteYN)) {
			cp.item("ratio", 100.0);
			cp.item("complete_yn", "Y");
			if("N".equals(pPreCompleteYN)) cp.item("complete_date", Malgn.time("yyyyMMddHHmmss"));
		} else {
			cp.item("complete_yn", "N");
			cp.item("complete_date", "");
		}

		if(pExists) {
			if(!cp.update("course_user_id = " + cuinfo.i("id") + " AND lesson_id = " + parentLid)) return -4;
		} else {
			cp.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
			if(!cp.insert()) return -5;
		}

		return "N".equals(pPreCompleteYN) && "Y".equals(pCompleteYN) ? 2 : 1;
	}
}
