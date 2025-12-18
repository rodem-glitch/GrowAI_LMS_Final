<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한(차시관리와 동일)
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");     //과정
int lid = m.ri("lid");     //부모 차시 레슨
int chapter = m.ri("chapter");
String mode = m.rs("mode");
if(cid == 0 || lid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();
CourseLessonVideoDao clv = new CourseLessonVideoDao();
ContentDao content = new ContentDao();

//과정 정보
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 과정 정보가 없습니다."); return; }

//부모 차시 정보
DataSet linfo = lesson.find("id = " + lid + " AND status != -1 AND site_id = " + siteId + "");
if(!linfo.next()) { m.jsError("해당 차시 정보가 없습니다."); return; }

//왜: “같은 실제 영상(같은 시작파일/키)” 중복을 화면/서버에서 같이 막기 위해,
//    비교용으로 부모(메인) 영상의 키를 미리 계산해 둡니다.
String parentVideoKey = !"".equals(linfo.s("start_url")) ? linfo.s("start_url").trim()
	: (!"".equals(linfo.s("mobile_a")) ? linfo.s("mobile_a").trim() : linfo.s("mobile_i").trim());
String parentVideoKeyMd5 = !"".equals(parentVideoKey) ? m.md5(parentVideoKey) : "";

//현재 등록된 서브영상 목록
DataSet videoList = clv.query(
	"SELECT v.video_id, v.sort, l.lesson_nm, l.total_time, l.complete_time, l.lesson_type, l.start_url, l.mobile_a, l.mobile_i "
	+ " FROM " + clv.table + " v "
	+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
	+ " WHERE v.course_id = " + cid
	+ " AND v.lesson_id = " + lid
	+ " AND v.site_id = " + siteId
	+ " AND v.status = 1 "
	+ " ORDER BY v.sort ASC "
);

//왜: 화면에서 중복 선택을 “바로” 막으려면, 각 행에 안전한 비교값이 필요합니다.
//    start_url(키/파일경로)이 길거나 특수문자가 포함될 수 있어 MD5로 변환해 전달합니다.
videoList.first();
while(videoList.next()) {
	String key = !"".equals(videoList.s("start_url")) ? videoList.s("start_url").trim()
		: (!"".equals(videoList.s("mobile_a")) ? videoList.s("mobile_a").trim() : videoList.s("mobile_i").trim());
	videoList.put("video_key_md5", !"".equals(key) ? m.md5(key) : "");
}
videoList.first();

//서브영상 구성/순서 저장
if(m.isPost()) {

	//모드가 없으면 save로 처리(기본)
	if("".equals(mode)) mode = "save";

	if("add".equals(mode)) {
		//선택 추가: 기존 목록 뒤에 추가합니다.
		String[] idx = f.getArr("lidx");
		if(idx != null && idx.length > 0) {

			// 왜: 레슨ID가 다르더라도 “같은 실제 영상(같은 시작파일/키)”을 여러 번 넣으면
			//     학습자 화면에서는 같은 영상이 반복 재생되어 혼란이 생깁니다.
			//     그래서 DB 저장 단계에서 “영상 내용 기준(시작파일/키)” 중복도 함께 막습니다.
			java.util.HashSet<String> existingKeys = new java.util.HashSet<String>();

			//부모(메인) 영상의 “영상키(시작파일)”도 중복 비교에 포함합니다.
			String parentKey = !"".equals(linfo.s("start_url")) ? linfo.s("start_url").trim()
				: (!"".equals(linfo.s("mobile_a")) ? linfo.s("mobile_a").trim() : linfo.s("mobile_i").trim());
			if(!"".equals(parentKey)) existingKeys.add(parentKey);

			//이미 등록된 서브영상들의 키도 모아둡니다.
			DataSet exists = clv.query(
				"SELECT l.start_url, l.mobile_a, l.mobile_i "
				+ " FROM " + clv.table + " v "
				+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 AND l.site_id = " + siteId + " "
				+ " WHERE v.course_id = " + cid + " AND v.lesson_id = " + lid + " AND v.site_id = " + siteId + " AND v.status = 1 "
			);
			while(exists.next()) {
				String key = !"".equals(exists.s("start_url")) ? exists.s("start_url").trim()
					: (!"".equals(exists.s("mobile_a")) ? exists.s("mobile_a").trim() : exists.s("mobile_i").trim());
				if(!"".equals(key)) existingKeys.add(key);
			}

			int maxSort = clv.getOneInt(
				"SELECT IFNULL(MAX(sort),0) FROM " + clv.table
				+ " WHERE course_id = " + cid + " AND lesson_id = " + lid + " AND site_id = " + siteId + " AND status = 1"
			);
			for(int i = 0; i < idx.length; i++) {
				int vid = m.parseInt(idx[i]);
				if(vid == 0) continue;
				if(0 < clv.findCount("course_id = " + cid + " AND lesson_id = " + lid + " AND video_id = " + vid + " AND site_id = " + siteId + " AND status = 1")) continue;

				//영상키(시작파일/URL) 기준 중복 체크
				DataSet vinfo = lesson.find("id = " + vid + " AND status = 1 AND site_id = " + siteId + "", "start_url, mobile_a, mobile_i");
				if(vinfo.next()) {
					String vkey = !"".equals(vinfo.s("start_url")) ? vinfo.s("start_url").trim()
						: (!"".equals(vinfo.s("mobile_a")) ? vinfo.s("mobile_a").trim() : vinfo.s("mobile_i").trim());
					if(!"".equals(vkey) && existingKeys.contains(vkey)) continue;
					if(!"".equals(vkey)) existingKeys.add(vkey);
				}

				clv.insertItem(cid, lid, vid, ++maxSort, siteId);
			}
		}
	} else if("save".equals(mode)) {
		//전체 저장: 현재 화면 순서를 그대로 DB에 반영합니다.
		String[] vids = f.getArr("video_id");
		clv.deleteList(cid, lid, siteId);
		if(vids != null) {
			// 왜: 사용자가 브라우저 조작/오류 등으로 중복된 값을 보내더라도
			//     저장 결과는 항상 “중복 없는 목록”이 되도록 안전장치를 둡니다.
			java.util.HashSet<Integer> seenVideoIds = new java.util.HashSet<Integer>();
			java.util.HashSet<String> seenKeys = new java.util.HashSet<String>();

			//부모(메인) 영상과 같은 시작파일/키가 있으면 중복이므로 미리 등록해 둡니다.
			String parentKey = !"".equals(linfo.s("start_url")) ? linfo.s("start_url").trim()
				: (!"".equals(linfo.s("mobile_a")) ? linfo.s("mobile_a").trim() : linfo.s("mobile_i").trim());
			if(!"".equals(parentKey)) seenKeys.add(parentKey);

			for(int i = 0; i < vids.length; i++) {
				int vid = m.parseInt(vids[i]);
				if(vid == 0) continue;
				if(seenVideoIds.contains(vid)) continue;

				//영상키(시작파일/URL) 기준 중복 체크
				DataSet vinfo = lesson.find("id = " + vid + " AND status = 1 AND site_id = " + siteId + "", "start_url, mobile_a, mobile_i");
				if(vinfo.next()) {
					String vkey = !"".equals(vinfo.s("start_url")) ? vinfo.s("start_url").trim()
						: (!"".equals(vinfo.s("mobile_a")) ? vinfo.s("mobile_a").trim() : vinfo.s("mobile_i").trim());
					if(!"".equals(vkey) && seenKeys.contains(vkey)) continue;
					if(!"".equals(vkey)) seenKeys.add(vkey);
				}

				seenVideoIds.add(vid);
				clv.insertItem(cid, lid, vid, i + 1, siteId);
			}
		}
	}

	//부모 영상(기존 차시 영상)도 항상 포함
	//왜: “총 학습/인정시간 = 이 차시에 등록된 모든 영상(기존 메인 + 추가 서브)의 합”이 되어야 하므로,
	//     운영자가 서브영상만 추가해도 기존 메인 영상까지 합산/재생 목록에 자동 포함시키기 위함입니다.
	boolean hasAnyVideo = 0 < clv.findCount("course_id = " + cid + " AND lesson_id = " + lid + " AND site_id = " + siteId + " AND status = 1");
	boolean hasParentVideo = 0 < clv.findCount("course_id = " + cid + " AND lesson_id = " + lid + " AND video_id = " + lid + " AND site_id = " + siteId + " AND status = 1");
	//부모 차시가 동영상 계열일 때만 자동 포함(혼합 타입으로 인한 사이드 이펙트 방지)
	String[] videoTypes = {"01", "03", "04", "05", "07"};
	if(hasAnyVideo && !hasParentVideo && Malgn.inArray(linfo.s("lesson_type"), videoTypes)) {

		// 왜: 레슨ID는 다르지만 시작파일/키가 같은 영상이 이미 서브로 들어있다면,
		//     부모 영상을 추가하면 “같은 영상이 2번”이 되어버립니다.
		//     이 경우에는 부모를 굳이 넣지 않고 중복을 피합니다.
		String parentKey = !"".equals(linfo.s("start_url")) ? linfo.s("start_url").trim()
			: (!"".equals(linfo.s("mobile_a")) ? linfo.s("mobile_a").trim() : linfo.s("mobile_i").trim());
		boolean parentKeyDup = false;
		if(!"".equals(parentKey)) {
			int dupCnt = clv.getOneInt(
				"SELECT COUNT(1) FROM " + clv.table + " v "
				+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 AND l.site_id = " + siteId + " "
				+ " WHERE v.course_id = " + cid + " AND v.lesson_id = " + lid + " AND v.site_id = " + siteId + " AND v.status = 1 "
				+ " AND (l.start_url = '" + m.addSlashes(parentKey) + "' OR l.mobile_a = '" + m.addSlashes(parentKey) + "' OR l.mobile_i = '" + m.addSlashes(parentKey) + "')"
			);
			parentKeyDup = 0 < dupCnt;
		}

		if(!parentKeyDup) {
			//기존 목록의 순서를 한 칸씩 밀고, 부모 영상을 1번으로 넣습니다.
			clv.execute(
				"UPDATE " + clv.table + " SET sort = sort + 1 "
				+ " WHERE course_id = " + cid + " AND lesson_id = " + lid + " AND site_id = " + siteId + " AND status = 1"
			);
			clv.insertItem(cid, lid, lid, 1, siteId);
		}
	}

	//합산 시간 캐시 재계산
	DataSet sums = clv.query(
		"SELECT SUM(l.total_time) total_time, SUM(l.complete_time) complete_time, COUNT(*) cnt "
		+ " FROM " + clv.table + " v "
		+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
		+ " WHERE v.course_id = " + cid
		+ " AND v.lesson_id = " + lid
		+ " AND v.site_id = " + siteId
		+ " AND v.status = 1 "
	);
	int totalMin = 0;
	int completeMin = 0;
	int cnt = 0;
	if(sums.next()) {
		totalMin = sums.i("total_time");
		completeMin = sums.i("complete_time");
		cnt = sums.i("cnt");
	}

	courseLesson.item("multi_yn", cnt > 0 ? "Y" : "N");
	courseLesson.item("multi_total_time", totalMin);
	courseLesson.item("multi_complete_time", completeMin);
	courseLesson.update("course_id = " + cid + " AND lesson_id = " + lid);

	m.jsAlert("저장되었습니다.");

	//왜: 서브영상이 0개(다중영상 해제)면 강의목차 화면에서는 '메인(부모) 차시' 시간이 보여야 합니다.
	//    또한 다중영상이어도 합산 시간이 0이면(데이터 미입력 등) 기존 화면 로직과 동일하게 부모 시간을 유지합니다.
	//    그래서 opener에는 “강의목차에서 실제로 보일 값”으로 보내서 즉시 갱신 시 0분으로 보이는 문제를 막습니다.
	int displayTotalMin = totalMin > 0 ? totalMin : linfo.i("total_time");
	int displayCompleteMin = completeMin > 0 ? completeMin : linfo.i("complete_time");

	// 왜: 이 페이지의 POST는 target="sysfrm"(iframe)로 보내기 때문에,
	//     기본 jsReplace()를 쓰면 iframe만 새로고침되어 화면이 갱신되지 않습니다.
	//     그래서 parent(팝업 본문)를 새로고침하고, opener(강의목차 화면)의 시간도 바로 갱신합니다.
	m.js(
		"try {"
		+ " if(parent.opener && !parent.opener.closed) {"
		+ "  if(typeof parent.opener.updateMultiLessonTime === 'function') {"
		+ "   parent.opener.updateMultiLessonTime(" + lid + ", " + displayTotalMin + ", " + displayCompleteMin + ");"
		+ "  }"
		+ "  parent.opener.location.reload();"
		+ " }"
		+ "} catch(e) {}"
	);
	m.jsReplace("lesson_video.jsp?" + m.qs("mode"), "parent");
	return;
}

//선택 목록 검색 폼
f.addElement("s_content", null, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//이미 등록된 서브영상 제외용 id 목록
StringBuffer vbuf = new StringBuffer();
videoList.first();
while(videoList.next()) { vbuf.append(","); vbuf.append(videoList.i("video_id")); }
String vIdx = videoList.size() == 0 ? "" : vbuf.toString().substring(1);
videoList.first();

//서브영상 선택 목록(온라인 동영상 강의만 노출)
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(f.getInt("s_listnum", 20));
lm.setTable(lesson.table + " a LEFT JOIN " + content.table + " c ON c.id = a.content_id AND c.status = 1");
lm.setFields("a.*, c.content_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.use_yn = 'Y'");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.onoff_type = 'N'"); //온라인

//영상 타입(동영상/MP4/외부링크 등)만 1차로 허용
lm.addWhere("a.lesson_type IN ('01','03','04','05','07')");

if(!"".equals(vIdx)) lm.addWhere("a.id NOT IN (" + vIdx + ")");

lm.addSearch("a.content_id", f.get("s_content"));
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.lesson_nm, a.author, a.start_url, c.content_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy("a.content_id desc, a.sort asc, a.id desc");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), lesson.onoffTypes));
	list.put("total_time_conv", m.nf(list.i("total_time")));
	list.put("content_nm_conv", 0 < list.i("content_id") ? list.s("content_nm") : "[미지정]");

	//왜: 화면(체크박스)에서도 “같은 영상(같은 키)”을 동시에 고르지 못하게 하려면,
	//    각 레슨의 영상키를 안전한 문자열(MD5)로 내려줘야 합니다.
	String key = !"".equals(list.s("start_url")) ? list.s("start_url").trim()
		: (!"".equals(list.s("mobile_a")) ? list.s("mobile_a").trim() : list.s("mobile_i").trim());
	list.put("video_key_md5", !"".equals(key) ? m.md5(key) : "");
}

//출력
p.setLayout("pop");
p.setBody("course.lesson_video");
p.setVar("p_title", "다중 영상 차시 구성");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("cid", cid);
p.setVar("lid", lid);
p.setVar("chapter", chapter);
p.setVar("course", cinfo);
p.setVar("lesson", linfo);
p.setVar("parent_video_key_md5", parentVideoKeyMd5);

p.setLoop("video_list", videoList);
p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("content_list", content.find(("C".equals(userKind) ? "manager_id = " + userId + " AND " : "") + "status != -1 AND site_id = " + siteId + "", "*", "content_nm ASC"));
p.setLoop("types", m.arr2loop(lesson.allLessonTypes));
p.display();

%>
