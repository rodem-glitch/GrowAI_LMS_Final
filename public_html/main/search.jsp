<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.io.*" %><%@ page import="java.net.*" %><%@ page import="java.nio.charset.StandardCharsets" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//기본키
String keyword = m.replace(m.rs("s_keyword").trim().replaceAll("[^가-힣a-zA-Z0-9\\s]", ""), " ", "|");
while(-1 < keyword.indexOf("||")) keyword = m.replace(keyword, "||", "|");
if(keyword.startsWith("|")) keyword = keyword.substring(1);
if(keyword.endsWith("|")) keyword = keyword.substring(0, keyword.length() - 1);
if("".equals(keyword)) { m.jsError(_message.get("alert.common.enter_keyword")); return; }
if(100 < keyword.length()) keyword = m.cutString(keyword, 100, "");

// 왜: DB 정규식(REGEXP) 검색용 키워드(keyword)는 '|' 구분자를 쓰지만,
//     벡터(추천) 검색은 자연어 입력이 더 잘 맞기 때문에 공백 기반 query를 따로 준비합니다.
String vectorQuery = m.rs("s_keyword").trim();
vectorQuery = vectorQuery.replaceAll("[^가-힣a-zA-Z0-9\\s]", " ");
vectorQuery = vectorQuery.replaceAll("\\s+", " ").trim();
if(vectorQuery.length() > 200) vectorQuery = m.cutString(vectorQuery, 200, "");

// 왜: 신규 메인에서 검색한 경우 동일한 헤더/푸터를 쓰기 위해 분기합니다.
String chParam = m.rs("ch");
boolean isNewMain = "new_main".equals(chParam);

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
PostDao post = new PostDao();
ClPostDao clPost = new ClPostDao();
BoardDao board = new BoardDao();
TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao();
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
SearchLogDao searchLog = new SearchLogDao(request);

// 사용자 정보 (헤더 표시용)
DataSet uinfo = null;
if(userId > 0) {
	uinfo = user.find("id = " + userId + " AND status = 1");
	if(!uinfo.next()) uinfo = null;
}

//로그
if(!searchLog.addLog(siteId, userId, m.rs("s_keyword"))) { }

//폼체크
Form f2 = new Form("form_search");
f2.setRequest(request);
f2.addElement("s_keyword", null, null);

//변수
String today = m.time("yyyyMMdd");

// ===== 벡터(추천) 검색 - 학생 검색 추천(동영상/강의) =====
// 왜: 기존 통합검색은 DB REGEXP 기반이라 "의미 기반" 검색이 약합니다.
//     그래서 학생 벡터검색 결과(강의/동영상)를 기존 '강의' 영역에서 함께 보여주기 위해 여기서 미리 조회합니다.
DataSet recoLessonsAll = new DataSet();
DataSet recoLessonsPreview = new DataSet();
int recoLessonTotal = 0;
try {
	if(!"".equals(vectorQuery)) {
		String apiBase = System.getenv("POLYTECH_LMS_API_BASE");
		if(apiBase == null || "".equals(apiBase.trim())) apiBase = "http://localhost:8081";
		apiBase = apiBase.replaceAll("/+$", "");

		String url = apiBase + "/student/content-recommend/search";

		JSONObject payload = new JSONObject();
		if(userId > 0) payload.put("userId", userId);
		payload.put("siteId", siteId);
		payload.put("query", vectorQuery);
		// 왜: '더보기'에서는 더 많이 보여줄 수 있어야 해서 넉넉히 받아옵니다. (상단은 5개만 미리보기)
		payload.put("topK", 200);

		String responseBody = "";
		int httpCode = 0;

		HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
		conn.setRequestMethod("POST");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(20000);
		conn.setDoOutput(true);
		conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
		conn.setRequestProperty("Accept", "application/json");

		byte[] bodyBytes = payload.toString().getBytes(StandardCharsets.UTF_8);
		conn.setFixedLengthStreamingMode(bodyBytes.length);
		try(OutputStream os = conn.getOutputStream()) {
			os.write(bodyBytes);
		}

		httpCode = conn.getResponseCode();
		InputStream is = (httpCode >= 200 && httpCode < 300) ? conn.getInputStream() : conn.getErrorStream();
		if(is != null) {
			try(BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
				StringBuilder sb = new StringBuilder();
				String line;
				while((line = br.readLine()) != null) sb.append(line);
				responseBody = sb.toString();
			}
		}

		if(httpCode >= 200 && httpCode < 300) {
			DataSet recoRows = new DataSet();
			try {
				String trimmed = responseBody == null ? "" : responseBody.trim();
				if(trimmed.startsWith("[")) recoRows = malgnsoft.util.Json.decode(trimmed);
			} catch(Exception ignore) {}

			KollusDao kollus = new KollusDao(siteId);
			KollusMediaDao kollusMedia = new KollusMediaDao();
			HashMap<String, String> thumbCache = new HashMap<String, String>();

			while(recoRows.next()) {
				String lessonId = recoRows.s("lessonId");  // 콜러스 영상 키값 (예: "5vcd73vW")
				if("".equals(lessonId)) continue;

				// 왜: 템플릿에서는 '강의(courses)' 목록을 재사용하므로, 동일한 키로 맞춰서 내려줍니다.
				recoLessonsAll.addRow();
				recoLessonsAll.put("is_reco_video", true);
				recoLessonsAll.put("id", lessonId);
				recoLessonsAll.put("course_nm", recoRows.s("title"));
				recoLessonsAll.put("course_nm_conv", m.cutString(recoRows.s("title"), 48));
				recoLessonsAll.put("category_nm", recoRows.s("categoryNm"));
				recoLessonsAll.put("onoff_type_conv", "온라인");
				recoLessonsAll.put("recomm_yn", true);

				// 왜: 외부 콜러스 영상은 학습 상태가 없으므로 빈 값
				recoLessonsAll.put("status_badge", "");

				// 왜: 학생도 교수자처럼 작은 팝업으로 미리보기 재생이 필요합니다.
				String playUrl = "/kollus/preview.jsp?key=" + lessonId;
				recoLessonsAll.put("play_url", playUrl);

				recoLessonsAll.put("duration_conv", "");
				// 왜: 교수자 LMS와 동일하게 TB_KOLLUS_MEDIA.snapshot_url을 썸네일로 사용합니다.
				String thumbnail = thumbCache.get(lessonId);
				if(thumbnail == null) {
					String found = "";
					DataSet minfo = kollusMedia.find(
						"site_id = " + siteId + " AND media_content_key = ?",
						new String[] { lessonId }
					);
					if(minfo.next()) {
						found = minfo.s("snapshot_url");
					}

					if("".equals(found)) found = "/html/images/common/noimage_course.gif";
					thumbCache.put(lessonId, found);
					thumbnail = found;
				}
				recoLessonsAll.put("course_file_url", thumbnail);
			}

			recoLessonTotal = recoLessonsAll.size();
			recoLessonsAll.first();
			while(recoLessonsAll.next()) {
				if(recoLessonsPreview.size() >= 5) break;
				recoLessonsPreview.addRow(recoLessonsAll.getRow());
			}
		}
	}
} catch(Exception ignore) {}

//정보-과정
DataSet courses = new DataSet();
DataSet coursesAll = course.query(
	" SELECT a.*, c.category_nm "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " WHERE a.course_nm REGEXP ? AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.close_yn = 'N' AND a.status = 1 "
	+ " AND (a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
	+ " ORDER BY a.id desc "
	, new Object[] {keyword}
);
int courseTotal = coursesAll.size();
while(coursesAll.next()) {
	if(coursesAll.i("__ord") > 5) break;

	coursesAll.put("request_date", "-");
	if("R".equals(coursesAll.s("course_type"))) {
		coursesAll.put("is_regular", true);
		coursesAll.put("request_date", m.time(_message.get("format.date.dot"), coursesAll.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), coursesAll.s("request_edate")));
		coursesAll.put("study_date", m.time(_message.get("format.date.dot"), coursesAll.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), coursesAll.s("study_edate")));
		coursesAll.put("ready_block", 0 > m.diffDate("D", coursesAll.s("request_sdate"), today));
	} else if("A".equals(coursesAll.s("course_type"))) {
		coursesAll.put("is_regular", false);
		coursesAll.put("request_date", "상시");
		coursesAll.put("study_date", "상시");
		coursesAll.put("ready_block", false);
	}

	coursesAll.put("course_nm_conv", m.cutString(coursesAll.s("course_nm"), 48));
	
	coursesAll.put("subtitle_conv", m.nl2br(coursesAll.s("subtitle")));
	coursesAll.put("content_conv", m.cutString(m.stripTags(coursesAll.s("subtitle")), 120));
	//coursesAll.put("content_conv", !"".equals(coursesAll.s("subtitle_conv")) ? coursesAll.s("subtitle_conv") : m.cutString(m.stripTags(coursesAll.s("content1")), 120));

	if(!"".equals(coursesAll.s("course_file"))) {
		coursesAll.put("course_file_url", m.getUploadUrl(coursesAll.s("course_file")));
	} else {
		coursesAll.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
	
	coursesAll.put("is_online", "N".equals(coursesAll.s("onoff_type")));
	coursesAll.put("is_offline", "F".equals(coursesAll.s("onoff_type")));
	coursesAll.put("is_blend", "B".equals(coursesAll.s("onoff_type")));
	coursesAll.put("is_package", "P".equals(coursesAll.s("onoff_type")));
	coursesAll.put("onoff_type_conv", m.getValue(coursesAll.s("onoff_type"), course.onoffPackageTypesMsg));

	coursesAll.put("tutor_nm", courseTutor.getTutorSummary(coursesAll.i("id")));

	courses.addRow(coursesAll.getRow());
}

// ===== 강의(과정) + 벡터(추천) 강의 합치기(미리보기) =====
// 왜: 사용자는 검색결과에서 '강의' 영역만 보면 되므로, 벡터검색 결과를 같은 리스트에 섞어 보여줍니다.
DataSet coursesMerged = new DataSet();
recoLessonsPreview.first();
while(recoLessonsPreview.next()) {
	coursesMerged.addRow(recoLessonsPreview.getRow());
}
courses.first();
while(courses.next()) {
	if(coursesMerged.size() >= 5) break;
	coursesMerged.addRow(courses.getRow());
}

//정보-방송
DataSet webtvs = new DataSet();
DataSet webtvsAll = webtv.query(
	" SELECT a.*, c.category_nm, IF('" + today + "' >= a.open_date, 'Y', 'N') is_open "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.status = 1 "
	+ " AND (a.webtv_nm REGEXP ? OR a.subtitle REGEXP ? OR a.content REGEXP ? OR a.keywords REGEXP ?) "
	+ " AND a.open_date <= '" + m.time("yyyyMMddHHmmss") + "'"
	+ " AND (a.target_yn = 'N' " //시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + webtvTarget.table + " WHERE webtv_id = a.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ " AND (c.target_yn = 'N' " //카테고리시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = c.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ " ORDER BY a.open_date desc, a.id desc "
	, new Object[] {keyword, keyword, keyword, keyword}
);
int webtvTotal = webtvsAll.size();
while(webtvsAll.next()) {
	if(webtvsAll.i("__ord") > 5) break;

	webtvsAll.put("webtv_nm_conv", m.cutString(webtvsAll.s("webtv_nm"), 70));
	
	webtvsAll.put("subtitle_conv", m.nl2br(webtvsAll.s("subtitle")));
	webtvsAll.put("length_conv", m.strrpad(webtvsAll.s("length_min"), 2, "0") + ":" + m.strrpad(webtvsAll.s("length_sec"), 2, "0"));

	if(!"".equals(webtvsAll.s("webtv_file"))) {
		webtvsAll.put("webtv_file_url", m.getUploadUrl(webtvsAll.s("webtv_file")));
	} else if("".equals(webtvsAll.s("webtv_file_url"))) {
		webtvsAll.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
	}

	webtvsAll.put("content_width_conv", webtvsAll.i("content_width") + 20);
	webtvsAll.put("content_height_conv", webtvsAll.i("content_height") + 23);
	
	webtvsAll.put("hit_cnt_conv", m.nf(webtvsAll.i("hit_cnt")));
	webtvsAll.put("reg_date_conv", m.time(_message.get("format.datetime.dot"), webtvsAll.s("reg_date")));
	webtvsAll.put("open_date_conv", m.time(_message.get("format.datetime.dot"), webtvsAll.s("open_date")));

	webtvs.addRow(webtvsAll.getRow());
}

//정보-강사
DataSet tutors = new DataSet();
DataSet tutorsAll = course.query(
	" SELECT a.*, c.category_nm "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = a.id "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = ct.user_id AND t.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.close_yn = 'N' AND a.status = 1 "
	+ " AND t.tutor_nm REGEXP ? "
	+ " AND (a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
	+ " ORDER BY a.id desc "
	, new Object[] {keyword}
);
int tutorTotal = tutorsAll.size();
while(tutorsAll.next()) {
	if(tutorsAll.i("__ord") > 5) break;

	tutorsAll.put("request_date", "-");
	if("R".equals(tutorsAll.s("course_type"))) {
		tutorsAll.put("is_regular", true);
		tutorsAll.put("request_date", m.time(_message.get("format.date.dot"), tutorsAll.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), tutorsAll.s("request_edate")));
		tutorsAll.put("study_date", m.time(_message.get("format.date.dot"), tutorsAll.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), tutorsAll.s("study_edate")));
		tutorsAll.put("ready_block", 0 > m.diffDate("D", tutorsAll.s("request_sdate"), today));
	} else if("A".equals(tutorsAll.s("course_type"))) {
		tutorsAll.put("is_regular", false);
		tutorsAll.put("request_date", "상시");
		tutorsAll.put("study_date", "상시");
		tutorsAll.put("ready_block", false);
	}

	tutorsAll.put("course_nm_conv", m.cutString(tutorsAll.s("course_nm"), 48));
	
	tutorsAll.put("subtitle_conv", m.nl2br(tutorsAll.s("subtitle")));
	tutorsAll.put("content_conv", m.cutString(m.stripTags(tutorsAll.s("subtitle")), 120));
	//tutorsAll.put("content_conv", !"".equals(tutorsAll.s("subtitle_conv")) ? tutorsAll.s("subtitle_conv") : m.cutString(m.stripTags(tutorsAll.s("content1")), 120));

	if(!"".equals(tutorsAll.s("course_file"))) {
		tutorsAll.put("course_file_url", m.getUploadUrl(tutorsAll.s("course_file")));
	} else {
		tutorsAll.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
	
	tutorsAll.put("is_online", "N".equals(tutorsAll.s("onoff_type")));
	tutorsAll.put("is_offline", "F".equals(tutorsAll.s("onoff_type")));
	tutorsAll.put("is_blend", "B".equals(tutorsAll.s("onoff_type")));
	tutorsAll.put("is_package", "P".equals(tutorsAll.s("onoff_type")));
	tutorsAll.put("onoff_type_conv", m.getValue(tutorsAll.s("onoff_type"), course.onoffPackageTypesMsg));

	tutorsAll.put("tutor_nm", courseTutor.getTutorSummary(tutorsAll.i("id")));

	tutors.addRow(tutorsAll.getRow());
}

//정보-게시물
DataSet posts = new DataSet();
DataSet postsAll = post.query(
	" SELECT a.*, b.board_nm, b.code, b.layout, b.comment_yn "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON b.id = a.board_id AND b.site_id = " + siteId + " AND b.status = 1 "
		+ (userId > 0 ? " AND b.auth_list LIKE '%|U|%' " : " AND b.auth_list LIKE '%|0|%' ")
	+ " WHERE (a.subject REGEXP ? OR a.content REGEXP ?) "
	+ " AND a.site_id = " + siteId + " AND a.secret_yn = 'N' AND a.display_yn = 'Y' AND a.status = 1 AND a.depth = 'A' "
	+ " ORDER BY a.id desc "
	, new Object[] {keyword, keyword}
);
int postTotal = postsAll.size();
while(postsAll.next()) {
	if(postsAll.i("__ord") > 5) break;

	postsAll.put("subject_conv", m.cutString(postsAll.s("subject"), 80));
	postsAll.put("reg_date_conv", m.time(_message.get("format.date.dot"), postsAll.s("reg_date")));
	postsAll.put("hit_cnt_conv", m.nf(postsAll.i("hit_cnt")));
	postsAll.put("comment_conv", postsAll.b("comment_yn") && postsAll.i("comm_cnt") > 0 ? "(" + postsAll.i("comm_cnt") + ")" : "");

	posts.addRow(postsAll.getRow());
}

//변수
int mergedCourseTotal = courseTotal + recoLessonTotal;
int searchTotal = tutorTotal + mergedCourseTotal + webtvTotal + postTotal;

//출력
// 왜: 신규 메인에서 들어온 검색은 새 레이아웃을 씁니다.
p.setLayout(isNewMain ? "new_main" : "search");
p.setBody("main.search");
p.setVar("p_title", "통합");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("subject_query", m.qs("id,subject"));
p.setVar("form_script", f2.getScript());

// 헤더용 사용자 정보
p.setVar("login_block", userId > 0 && uinfo != null);
if(userId > 0 && uinfo != null) {
	p.setVar("SYS_USERNAME", uinfo.s("user_nm"));
	String userNameForHeader = uinfo.s("user_nm");
	p.setVar("SYS_USERNAME_INITIAL", userNameForHeader.length() > 0 ? userNameForHeader.substring(0, 1) : "?");
} else {
	p.setVar("SYS_USERNAME", "");
	p.setVar("SYS_USERNAME_INITIAL", "");
}

p.setLoop("tutors", tutors);
p.setLoop("courses", coursesMerged);
p.setLoop("webtvs", webtvs);
p.setLoop("posts", posts);

//p.setVar("s_keyword", keyword.replaceAll("\\|", " "));
p.setVar("tutor_total", m.nf(tutorTotal));
p.setVar("course_total", m.nf(mergedCourseTotal));
p.setVar("webtv_total", m.nf(webtvTotal));
p.setVar("post_total", m.nf(postTotal));
p.setVar("search_total", m.nf(searchTotal));
p.setVar("no_result", 0 == searchTotal);

// 왜: '강의 더보기'는 벡터검색 전체 결과를 보여주는 모드로 이동시킵니다.
//     (기존 검색 파라미터를 그대로 유지하면서 mode만 추가)
p.setVar("course_more_query", m.qs() + "&mode=vector");
p.display();

%>
