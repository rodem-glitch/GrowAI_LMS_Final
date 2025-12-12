<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//클라우드 데이터 가져오기
/*
 * 1. 회원
 * 2. 강의그룹(콘텐츠)
 * 3. 강의
 * 4. 과정
 * 5. 과정 카테고리
 * 6. 과정 강의
 * 7. 과정 강의 섹션
 * 8. 수강생
 * 9. 학습이력
 * 10. 수강생 진도정보
 * 11. 회원동의기록
 * 12. 게사판
 * 13. 게시판 카테고리
 * 14. 답변템플릿
 * 15. 게시글
 * 16. 과정게시판
 * 16. 과정게시글
 * */
String[] modules = {
        "user=>회원", "content=>강의그룹(콘텐츠)", "lesson=>강의", "course=>과정", "course_category=>과정카테고리"
        , "course_lesson=>과정강의", "course_lesson_section=>과정강의섹션", "course_user=>수강생"
        , "course_user_log=>학습이력", "course_progress=>수강생진도정보", "user_agreement=>회원동의기록"
        , "board=>게시판", "board_category=>게시판카테고리", "post=>게시글", "clboard=>과정게시판", "clpost=>과정게시글"
};

//객체
UserDao user = new UserDao();
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();
CourseDao course = new CourseDao();
LmCategoryDao courseCategory = new LmCategoryDao("course");
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseUserDao courseUser = new CourseUserDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
CourseProgressDao courseProgress = new CourseProgressDao();
AgreementLogDao agreementLog = new AgreementLogDao();
BoardDao board = new BoardDao();
CategoryDao category = new CategoryDao();
PostDao post = new PostDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();

//변수
Json j = new Json();
String f_mode = f.get("mode");

if(m.isPost() && "preview".equals(f_mode)) {

    //파일 저장하기
    File cloudData = f.saveFile("cloud_data");
    if(cloudData != null) {

        //변수
        boolean isError = false;

        //저장된 경로 가져오기
        String path = m.getUploadPath(f.getFileName("cloud_data"));

        //파일 읽기
        BufferedReader br = new BufferedReader(
                new FileReader(path),
                16 * 1024
        ); //파일을 16KBytes 씩 버퍼에 저장
        StringBuffer sb = new StringBuffer();
        try {
            String s;
            while ((s = br.readLine()) != null) {
                sb.append(s);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
            isError = true;
        } catch (Exception e) {
            e.printStackTrace();
            isError = true;
        } finally {
            br.close();
        }

        //파일 삭제하기
        if(!"".equals(path)) m.delFileRoot(path);

        if(isError) {
            m.jsAlert("파일을 읽는 중 오류가 발생했습니다.");
            m.js("parent.location.href = parent.location.href");
            return;
        }

        //포맷팅
        j.setJson(sb.toString());

        //회원정보
        int lastUserId = user.getOneInt("SELECT MAX(id) FROM " + user.table + "");
        DataSet userList = j.getDataSet("//user_list");
        int i = 1;
        userList.sort("id");
        while(userList.next()) {
            userList.put("__ord", i++);
            userList.put("prev_id", userList.i("id"));
            userList.put("expected_id", ++lastUserId);
            userList.put("user_kind_conv", m.getItem(userList.s("user_kind"), user.kinds));
            userList.put("mobile_conv", SimpleAES.decrypt(userList.s("mobile")));
            userList.put("birthday_conv", (!"".equals(userList.s("birthday")) && 8 == userList.s("birthday").length()) ? m.time("yyyy-MM-dd", userList.s("birthday")) : userList.s("birthday"));
        }
        p.setLoop("user_list", userList);
        p.setVar("user_list_total", userList.size());

        //콘텐츠정보
        int lastContentId = content.getOneInt("SELECT MAX(id) FROM " + content.table + "");
        DataSet contentList = j.getDataSet("//content_list");
        i = 1;
        contentList.sort("id");
        while(contentList.next()) {
            contentList.put("__ord", i++);
            contentList.put("prev_id", contentList.i("id"));
            contentList.put("expected_id", ++lastContentId);
            contentList.put("content_nm", contentList.s("content_nm"));
            contentList.put("description_conv", m.cutString(m.htt(contentList.s("description")), 50));
        }
        p.setLoop("content_list", contentList);
        p.setVar("content_list_total", contentList.size());

        //강의정보
        int lastLessonId = lesson.getOneInt("SELECT MAX(id) FROM " + lesson.table + "");
        DataSet lessonList = j.getDataSet("//lesson_list");
        i = 1;
        lessonList.sort("id");
        while(lessonList.next()) {
            lessonList.put("__ord", i++);
            lessonList.put("prev_id", lessonList.i("id"));
            lessonList.put("expected_id", ++lastLessonId);
            lessonList.put("content_id", lessonList.i("content_id"));
            lessonList.put("lesson_type_conv", m.getItem(lessonList.s("lesson_type"), lesson.types));
            lessonList.put("lesson_nm", lessonList.s("lesson_nm"));
            lessonList.put("start_url", lessonList.s("start_url"));
            lessonList.put("total_time", lessonList.s("total_time"));
            lessonList.put("complete_time", lessonList.s("complete_time"));
        }
        p.setLoop("lesson_list", lessonList);
        p.setVar("lesson_list_total", lessonList.size());

        //과정정보
        int lastCourseId = course.getOneInt("SELECT MAX(id) FROM " + course.table + "");
        DataSet courseList = j.getDataSet("//course_list");
        i = 1;
        courseList.sort("id");
        while(courseList.next()) {
            courseList.put("__ord", i++);
            courseList.put("prev_id", courseList.i("id"));
            courseList.put("expected_id", ++lastCourseId);
            courseList.put("course_type_conv", m.getItem(courseList.s("course_type"), course.types));
            courseList.put("onoff_type_conv", m.getItem(courseList.s("onoff_type"), course.onoffTypes));
            courseList.put("course_nm", courseList.s("course_nm"));
            courseList.put("price", courseList.s("price"));
            courseList.put("year", courseList.s("year"));
            courseList.put("step", courseList.s("step"));
        }
        p.setLoop("course_list", courseList);
        p.setVar("course_list_total", courseList.size());

        //과정카테고리정보
        int lastCourseCategoryId = courseCategory.getOneInt("SELECT MAX(id) FROM " + courseCategory.table + "");
        DataSet courseCategoryList = j.getDataSet("//course_category_list");
        i = 1;
        courseCategoryList.sort("parent_id");
        while(courseCategoryList.next()) {
            courseCategoryList.put("__ord", i++);
            courseCategoryList.put("prev_id", courseCategoryList.i("id"));
            courseCategoryList.put("expected_id", ++lastCourseCategoryId);
            courseCategoryList.put("parent_id", courseCategoryList.i("parent_id"));
            courseCategoryList.put("course_category_nm", courseCategoryList.s("category_nm"));
            courseCategoryList.put("list_num", courseCategoryList.i("list_num"));
            courseCategoryList.put("display_yn", m.getItem(courseCategoryList.s("display_yn"), new String[] { "Y=>노출", "N=>숨김"}));
            courseCategoryList.put("sort", courseCategoryList.i("sort"));
        }
        p.setLoop("course_category_list", courseCategoryList);
        p.setVar("course_category_list_total", courseCategoryList.size());

        //과정강의정보
        DataSet courseLessonList = j.getDataSet("//course_lesson_list");
        i = 1;
        courseLessonList.sort("course_id");
        while(courseLessonList.next()) {
            courseLessonList.put("__ord", i++);
            courseLessonList.put("course_id", courseLessonList.i("course_id"));
            courseLessonList.put("lesson_id", courseLessonList.i("lesson_id"));
            courseLessonList.put("section_id", courseLessonList.i("section_id"));
            courseLessonList.put("chapter", courseLessonList.i("chapter"));
            courseLessonList.put("lesson_hour", courseLessonList.d("lesson_hour"));
        }
        p.setLoop("course_lesson_list", courseLessonList);
        p.setVar("course_lesson_list_total", courseLessonList.size());

        //과정강의섹션정보
        int lastCourseLessonSectionId = courseSection.getOneInt("SELECT MAX(id) FROM " + courseSection.table + "");
        DataSet courseLessonSectionList = j.getDataSet("//course_section_list");
        i = 1;
        courseLessonSectionList.sort("course_id");
        while(courseLessonSectionList.next()) {
            courseLessonSectionList.put("__ord", i++);
            courseLessonSectionList.put("prev_id", courseLessonSectionList.i("id"));
            courseLessonSectionList.put("expected_id", ++lastCourseLessonSectionId);
            courseLessonSectionList.put("course_id", courseLessonSectionList.i("course_id"));
            courseLessonSectionList.put("section_nm", courseLessonSectionList.s("section_nm"));
        }
        p.setLoop("course_lesson_section_list", courseLessonSectionList);
        p.setVar("course_lesson_section_list_total", courseLessonSectionList.size());

        //수강생정보
        int lastCourseUserId = courseUser.getOneInt("SELECT MAX(id) FROM " + courseUser.table + "");
        DataSet courseUserList = j.getDataSet("//course_user_list");
        i = 1;
        courseUserList.sort("id");
        while(courseUserList.next()) {
            courseUserList.put("__ord", i++);
            courseUserList.put("prev_id", courseUserList.i("id"));
            courseUserList.put("expected_id", ++lastCourseUserId);
            courseUserList.put("course_id", courseUserList.i("course_id"));
            courseUserList.put("user_id", courseUserList.i("user_id"));
            courseUserList.put("start_date", m.time("yyyy.MM.dd", courseUserList.s("start_date")));
            courseUserList.put("end_date", m.time("yyyy.MM.dd", courseUserList.s("end_date")));
            courseUserList.put("progress_ratio", courseUserList.d("progress_ratio"));
            courseUserList.put("progress_score", courseUserList.d("progress_score"));
            courseUserList.put("total_score", courseUserList.d("total_score"));
            courseUserList.put("complete_yn", m.getItem(courseUserList.s("complete_yn"), courseUser.completeYn));
            courseUserList.put("complete_no", courseUserList.s("complete_no"));
            courseUserList.put("complete_date", m.time("yyyy.MM.dd", courseUserList.s("complete_date")));
            courseUserList.put("reg_date", m.time("yyyy.MM.dd", courseUserList.s("reg_date")));
            courseUserList.put("status", m.getItem(courseUserList.s("status"), courseUser.statusList));
        }
        p.setLoop("course_user_list", courseUserList);
        p.setVar("course_user_list_total", courseUserList.size());

        //학습이력
        int lastCourseUserLogId = courseUserLog.getOneInt("SELECT MAX(id) FROM " + courseUserLog.table + "");
        DataSet courseUserLogList = j.getDataSet("//course_user_log_list");
        i = 1;
        courseUserLogList.sort("id");
        while(courseUserLogList.next()) {
            courseUserLogList.put("__ord", i++);
            courseUserLogList.put("prev_id", courseUserLogList.i("id"));
            courseUserLogList.put("expected_id", ++lastCourseUserLogId);
            courseUserLogList.put("course_user_id", courseUserLogList.i("course_user_id"));
            courseUserLogList.put("user_id", courseUserLogList.i("user_id"));
            courseUserLogList.put("chapter", courseUserLogList.i("chapter"));
            courseUserLogList.put("progress_ratio", courseUserLogList.d("progress_ratio"));
            courseUserLogList.put("progress_complte_yn", courseUserLogList.s("progress_complte_yn"));
            courseUserLogList.put("user_ip_addr", courseUserLogList.s("user_ip_addr"));
        }
        p.setLoop("course_user_log_list", courseUserLogList);
        p.setVar("course_user_log_list_total", courseUserLogList.size());

        //수강생진도이력
        DataSet courseProgressList = j.getDataSet("//course_progress_list");
        i = 1;
        courseProgressList.sort("course_user_id");
        while(courseProgressList.next()) {
            courseProgressList.put("__ord", i++);
            courseProgressList.put("course_id", courseProgressList.i("course_id"));
            courseProgressList.put("lesson_id", courseProgressList.i("lesson_id"));
            courseProgressList.put("chapter", courseProgressList.i("chapter"));
            courseProgressList.put("course_user_id", courseProgressList.i("course_user_id"));
            courseProgressList.put("study_time", courseProgressList.i("study_time"));
            courseProgressList.put("ratio", courseProgressList.d("ratio"));
            courseProgressList.put("complete_yn", courseProgressList.s("complete_yn"));
        }
        p.setLoop("course_progress_list", courseProgressList);
        p.setVar("course_progress_list_total", courseProgressList.size());

        //회원동의기록 user_agreement
        int lastAgreementLogId = agreementLog.getOneInt("SELECT MAX(id) FROM " + agreementLog.table + "");
        DataSet userAgreementList = j.getDataSet("//user_agreement_list");
        i = 1;
        userAgreementList.sort("id");
        while(userAgreementList.next()) {
            userAgreementList.put("__ord", i++);
            userAgreementList.put("prev_id", userAgreementList.i("id"));
            userAgreementList.put("expected_id", ++lastAgreementLogId);
            userAgreementList.put("user_id", userAgreementList.i("user_id"));
            userAgreementList.put("type", m.getItem(userAgreementList.s("type"), agreementLog.types));
            userAgreementList.put("agreement_yn", m.getItem(userAgreementList.s("agreement_yn"), agreementLog.receiveYn));
        }
        p.setLoop("user_agreement_list", userAgreementList);
        p.setVar("user_agreement_list_total", userAgreementList.size());

        //게시판
        int lastBoardId = board.getOneInt("SELECT MAX(id) FROM " + board.table + "");
        DataSet boardList = j.getDataSet("//board_list");
        i = 1;
        boardList.sort("id");
        while(boardList.next()) {
            boardList.put("__ord", i++);
            boardList.put("prev_id", boardList.i("id"));
            boardList.put("expected_id", ++lastBoardId);
            boardList.put("board_nm", boardList.s("board_nm"));
            boardList.put("type", m.getItem(boardList.s("board_type"), board.types));
            boardList.put("status", m.getItem(boardList.s("status"), board.statusList));
        }
        p.setLoop("board_list", boardList);
        p.setVar("board_list_total", boardList.size());

        //게시판 카테고리
        int lastBoardCategoryId = category.getOneInt("SELECT MAX(id) FROM " + category.table + "");
        DataSet boardCategoryList = j.getDataSet("//board_category_list");
        i = 1;
        boardCategoryList.sort("id");
        while(boardCategoryList.next()) {
            boardCategoryList.put("__ord", i++);
            boardCategoryList.put("prev_id", boardCategoryList.i("id"));
            boardCategoryList.put("expected_id", ++lastBoardCategoryId);
            boardCategoryList.put("module", boardCategoryList.s("module"));
            boardCategoryList.put("module_id", boardCategoryList.s("module_id"));
            boardCategoryList.put("status", m.getItem(boardCategoryList.s("status"), board.statusList));
        }
        p.setLoop("board_category_list", boardCategoryList);
        p.setVar("board_category_list_total", boardCategoryList.size());

        //게시글
        int lastPostId = post.getOneInt("SELECT MAX(id) FROM " + post.table + "");
        DataSet postList = j.getDataSet("//post_list");
        i = 1;
        postList.sort("id");
        while(postList.next()) {
            postList.put("__ord", i++);
            postList.put("prev_id", postList.i("id"));
            postList.put("expected_id", ++lastPostId);
            postList.put("board_id", postList.s("board_id"));
            postList.put("category_id", postList.s("category_id"));
            postList.put("status", m.getItem(postList.s("status"), post.statusList));
        }
        p.setLoop("post_list", postList);
        p.setVar("post_list_total", postList.size());

        //과정게시판
        int lastClBoardId = clBoard.getOneInt("SELECT MAX(id) FROM " + clBoard.table + "");
        DataSet clBoardList = j.getDataSet("//clboard_list");
        i = 1;
        clBoardList.sort("id");
        while(clBoardList.next()) {
            clBoardList.put("__ord", i++);
            clBoardList.put("prev_id", clBoardList.i("id"));
            clBoardList.put("expected_id", ++lastClBoardId);
            clBoardList.put("course_id", clBoardList.s("course_id"));
            clBoardList.put("code", clBoardList.s("code"));
            clBoardList.put("status", m.getItem(clBoardList.s("status"), post.statusList));
        }
        p.setLoop("clboard_list", clBoardList);
        p.setVar("clboard_list_total", clBoardList.size());

        //과정게시글
        int lastClPostId = clPost.getOneInt("SELECT MAX(id) FROM " + clPost.table + "");
        DataSet clPostList = j.getDataSet("//clpost_list");
        i = 1;
        clPostList.sort("id");
        while(clPostList.next()) {
            clPostList.put("__ord", i++);
            clPostList.put("prev_id", clPostList.i("id"));
            clPostList.put("expected_id", ++lastClPostId);
            clPostList.put("course_id", clPostList.s("course_id"));
            clPostList.put("board_id", clPostList.s("board_id"));
            clPostList.put("course_user_id", clPostList.s("course_user_id"));
            clPostList.put("status", m.getItem(clPostList.s("status"), post.statusList));
        }
        p.setLoop("clpost_list", clPostList);
        p.setVar("clpost_list_total", clPostList.size());

    } else {
        m.jsAlert("파일을 읽는 중 오류가 발생했습니다.");
        m.js("parent.location.href = parent.location.href");
        return;
    }


    //출력
    p.setLayout("blank");
    p.setBody("migration.migrate_from_cloud");

    p.setLoop("modules", m.arr2loop(modules));

    p.setVar("list_area", true);

    p.display();

    return;
} else if(m.isPost() && "migrate".equals(f_mode)) {

    //파일 저장하기
    File cloudData = f.saveFile("cloud_data");
    if(cloudData != null) {

        //변수
        boolean isError = false;

        //저장된 경로 가져오기
        String path = m.getUploadPath(f.getFileName("cloud_data"));

        //파일 읽기
        BufferedReader br = new BufferedReader(
                new FileReader(path),
                16 * 1024
        ); //파일을 16KBytes 씩 버퍼에 저장
        StringBuffer sb = new StringBuffer();
        try {
            String s;
            while ((s = br.readLine()) != null) {
                sb.append(s);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
            isError = true;
        } catch (Exception e) {
            e.printStackTrace();
            isError = true;
        } finally {
            br.close();
        }

        //파일 삭제하기
        if(!"".equals(path)) m.delFileRoot(path);

        if(isError) {
            m.jsAlert("파일을 읽는 중 오류가 발생했습니다.");
            m.js("parent.location.href = parent.location.href");
            return;
        }

        //포맷팅
        j.setJson(sb.toString());

        //회원등록
        JSONObject userJobj = new JSONObject();
        DataSet userList = j.getDataSet("//user_list");
        userList.sort("id");
        while(userList.next()) {
            user.clear(); //초기화
            int newId = user.getSequence();

            user.item("id", newId);
            user.item("site_id", 1);
            user.item("login_id", userList.s("login_id"));
            user.item("dept_id", userList.s("dept_id"));
            user.item("user_nm", userList.s("user_nm"));
            user.item("passwd", userList.s("passwd"));
            user.item("access_token", userList.s("access_token"));
            user.item("user_kind", userList.s("user_kind"));
            user.item("email", userList.s("email"));
            user.item("zipcode", userList.s("zipcode"));
            user.item("addr", userList.s("addr"));
            user.item("new_addr", userList.s("new_addr"));
            user.item("addr_dtl", userList.s("addr_dtl"));
            user.item("gender", userList.s("gender"));
            user.item("birthday", userList.s("birthday"));
            user.item("mobile", userList.s("mobile"));
            user.item("needs", userList.s("needs"));
            user.item("user_file", userList.s("user_file"));
            user.item("auth2_yn", userList.s("auth2_yn"));
            user.item("auth2_type", userList.s("auth2_type"));
            user.item("otp_key", userList.s("otp_key"));
            user.item("etc1", userList.s("etc1"));
            user.item("etc2", userList.s("etc2"));
            user.item("etc3", userList.s("etc3"));
            user.item("etc4", userList.s("etc4"));
            user.item("etc5", userList.s("etc5"));
            user.item("dupinfo", userList.s("dupinfo"));
            user.item("oauth_vendor", userList.s("oauth_vendor"));
            user.item("fail_cnt", userList.s("fail_cnt"));
            user.item("tutor_yn", userList.s("tutor_yn"));
            user.item("display_yn", userList.s("display_yn"));
            user.item("email_yn", userList.s("email_yn"));
            user.item("sms_yn", userList.s("sms_yn"));
            user.item("privacy_yn", userList.s("privacy_yn"));
            user.item("passwd_date", userList.s("passwd_date"));
            user.item("sleep_date", userList.s("sleep_date"));
            user.item("conn_date", userList.s("conn_date"));
            user.item("reg_date", userList.s("reg_date"));
            user.item("status", userList.s("status"));

            user.insert();
            if(newId > 0) {
                userJobj.put(userList.s("id"), "" + newId);
            }

        }
        //save userJobj
        saveMap("TB_USER", userJobj);

        //콘텐츠등록
        JSONObject contentJobj = new JSONObject();
        DataSet contentList = j.getDataSet("//content_list");
        contentList.sort("id");
        while(contentList.next()) {
            content.clear(); //초기화
            int newId = content.getSequence();

            int uid = userJobj.has(contentList.s("manager_id")) ? userJobj.getInt(contentList.s("manager_id")) : 0;

            content.item("id", newId);
            content.item("site_id", 1);
            content.item("category_id", contentList.s("category_id")); //사용안하는 컬럼
            content.item("content_nm", contentList.s("content_nm"));
            content.item("description", contentList.s("description"));
            content.item("manager_id", uid);
            content.item("reg_date", contentList.s("reg_date"));
            content.item("status", contentList.s("status"));

            content.insert();
            if(newId > 0) {
                contentJobj.put(contentList.s("id"), "" + newId);
            }

        }
        //save contentJobj
        saveMap("LM_CONTENT", contentJobj);

        //강의등록
        JSONObject lessonJobj = new JSONObject();
        DataSet lessonList = j.getDataSet("//lesson_list");
        lessonList.sort("id");
        while(lessonList.next()) {
            lesson.clear(); //초기화
            int newId = lesson.getSequence();

            int uid = userJobj.has(lessonList.s("manager_id")) ? userJobj.getInt(lessonList.s("manager_id")) : 0;
            int contentId = contentJobj.has(lessonList.s("content_id")) ? contentJobj.getInt(lessonList.s("content_id")) : 0;
            if(contentId == 0) continue;

            lesson.item("id", newId);
            lesson.item("site_id", 1);
            lesson.item("content_id", contentId);
            lesson.item("onoff_type", lessonList.s("onoff_type"));
            lesson.item("lesson_type", lessonList.s("lesson_type"));
            lesson.item("lesson_nm", lessonList.s("lesson_nm"));
            lesson.item("author", lessonList.s("author"));
            lesson.item("start_url", lessonList.s("start_url"));
            lesson.item("mobile_a", lessonList.s("mobile_a"));
            lesson.item("mobile_i", lessonList.s("mobile_i"));
            lesson.item("total_time", lessonList.i("total_time"));
            lesson.item("complete_time", lessonList.i("complete_time"));
            lesson.item("content_width", lessonList.s("content_width"));
            lesson.item("content_height", lessonList.s("content_height"));
            lesson.item("total_page", lessonList.s("total_page"));
            lesson.item("lesson_hour", lessonList.i("lesson_hour"));
            lesson.item("lesson_file", lessonList.s("lesson_file"));
            lesson.item("description", lessonList.s("description"));
            lesson.item("manager_id", uid);
            lesson.item("use_yn", lessonList.s("use_yn"));
            lesson.item("chat_yn", lessonList.s("chat_yn"));
            lesson.item("sort", lessonList.s("sort"));
            lesson.item("reg_date", lessonList.s("reg_date"));
            lesson.item("status", lessonList.s("status"));

            lesson.insert();
            if(newId > 0) {
                lessonJobj.put(lessonList.s("id"), "" + newId);
            }
        }
        //save lessonJobj
        saveMap("LM_LESSON", lessonJobj);

        //과정카테고리등록
        JSONObject courseCategoryJobj = new JSONObject();
        DataSet courseCategoryList = j.getDataSet("//course_category_list");
        courseCategoryList.sort("parent_id");
        while(courseCategoryList.next()) {
            courseCategory.clear();
            int newId = courseCategory.getSequence();

            int courseCategoryParentId = courseCategoryJobj.has(courseCategoryList.s("parent_id")) ? courseCategoryJobj.getInt(courseCategoryList.s("parent_id")) : 0;

            courseCategory.item("id", newId);
            courseCategory.item("site_id", 1);
            courseCategory.item("parent_id", courseCategoryParentId);
            courseCategory.item("category_nm", courseCategoryList.s("category_nm"));
            courseCategory.item("depth", courseCategoryList.s("depth"));
            courseCategory.item("sort", courseCategoryList.s("sort"));
            courseCategory.item("status", courseCategoryList.s("status"));

            courseCategory.insert();
            if(newId > 0) {
                courseCategoryJobj.put(courseCategoryList.s("id"), "" + newId);
            }

        }
        //save courseCategoryJobj
        saveMap("LM_CATEGORY", courseCategoryJobj);

        //과정, 차수과정 등록
        JSONObject courseJobj = new JSONObject();
        DataSet courseList = j.getDataSet("//course_list");
        courseList.sort("id");
        while(courseList.next()) {
            course.clear();
            int newId = course.getSequence();

            int uid = userJobj.has(courseList.s("manager_id")) ? userJobj.getInt(courseList.s("manager_id")) : 0;
            int categoryId = courseCategoryJobj.has(courseList.s("category_id")) ? courseCategoryJobj.getInt(courseList.s("category_id")) : 0;
            if("".equals(categoryId)) continue;

            course.item("id", newId);
            course.item("site_id", 1);
            //course.item("subject_id", courseList.s("subject_id"));
            course.item("category_id", categoryId);
            course.item("course_cd", courseList.s("course_cd"));
            course.item("year", courseList.s("year"));
            course.item("step", courseList.s("step"));
            course.item("course_type", courseList.s("course_type"));
            course.item("onoff_type", courseList.s("onoff_type"));
            course.item("course_nm", courseList.s("course_nm"));
            course.item("request_sdate", courseList.s("request_sdate"));
            course.item("request_edate", courseList.s("request_edate"));
            course.item("study_sdate", courseList.s("study_sdate"));
            course.item("study_edate", courseList.s("study_edate"));
            course.item("mobile_yn", courseList.s("mobile_yn"));
            course.item("evaluation_yn", courseList.s("evaluation_yn"));
            course.item("recomm_yn", courseList.s("recomm_yn"));
            course.item("auto_approve_yn", courseList.s("auto_approve_yn"));
            course.item("sms_yn", courseList.s("sms_yn"));
            course.item("lesson_day", courseList.s("lesson_day"));
            course.item("lesson_time", courseList.s("lesson_time"));
            course.item("taxfree_yn", courseList.s("taxfree_yn"));
            course.item("disc_group_yn", courseList.s("disc_group_yn"));
            course.item("list_price", courseList.s("list_price"));
            course.item("price", courseList.s("price"));
            course.item("memo_yn", courseList.s("memo_yn"));
            course.item("renew_price", courseList.s("renew_price"));
            course.item("renew_max_cnt", courseList.s("renew_max_cnt"));
            course.item("renew_yn", courseList.s("renew_yn"));
            course.item("credit", courseList.s("credit"));
            course.item("assign_progress", courseList.s("assign_progress"));
            course.item("assign_exam", courseList.s("assign_exam"));
            course.item("assign_homework", courseList.s("assign_homework"));
            course.item("assign_forum", courseList.s("assign_forum"));
            course.item("assign_etc", courseList.s("assign_etc"));
            course.item("assign_survey_yn", courseList.s("assign_survey_yn"));
            course.item("limit_progress", courseList.s("limit_progress"));
            course.item("limit_exam", courseList.s("limit_exam"));
            course.item("limit_homework", courseList.s("limit_homework"));
            course.item("limit_forum", courseList.s("limit_forum"));
            course.item("limit_etc", courseList.s("limit_etc"));
            course.item("limit_total_score", courseList.s("limit_total_score"));
            course.item("limit_people_yn", courseList.s("limit_people_yn"));
            course.item("limit_people", courseList.s("limit_people"));
            course.item("limit_lesson_yn", courseList.s("limit_lesson_yn"));
            course.item("limit_day", courseList.s("limit_day"));
            course.item("limit_lesson", courseList.s("limit_lesson"));
            course.item("limit_ratio_yn", courseList.s("limit_ratio_yn"));
            course.item("limit_ratio", courseList.s("limit_ratio"));
            course.item("limit_seek_yn", courseList.s("limit_seek_yn"));
            course.item("playrate_yn", courseList.s("playrate_yn"));
            course.item("push_survey_yn", courseList.s("push_survey_yn"));
            course.item("lesson_order_yn", courseList.s("lesson_order_yn"));
            course.item("class_member", courseList.s("class_member"));
            course.item("period_yn", courseList.s("period_yn"));
            course.item("speed_yn", courseList.s("speed_yn"));
            course.item("sample_lesson_id", courseList.s("sample_lesson_id"));
            course.item("target_yn", courseList.s("target_yn"));
            course.item("restudy_yn", courseList.s("restudy_yn"));
            course.item("restudy_day", courseList.s("restudy_day"));
            course.item("complete_auto_yn", courseList.s("complete_auto_yn"));
            course.item("before_course_id", courseList.s("before_course_id"));
            course.item("course_file", courseList.s("course_file"));
            course.item("close_yn", courseList.s("close_yn"));
            course.item("close_date", courseList.s("close_date"));
            course.item("lesson_display_ord", courseList.s("lesson_display_ord"));
            course.item("subtitle", courseList.s("subtitle"));
            course.item("content1_title", courseList.s("content1_title"));
            course.item("content1", courseList.s("content1"));
            course.item("content2_title", courseList.s("content2_title"));
            course.item("content2", courseList.s("content2"));
            course.item("keywords", courseList.s("keywords"));
            course.item("course_address", courseList.s("course_address"));
//            course.item("manager_id", courseList.s("manager_id")); //고민
            course.item("manager_id", uid);
            course.item("exam_yn", courseList.s("exam_yn"));
            course.item("homework_yn", courseList.s("homework_yn"));
            course.item("forum_yn", courseList.s("forum_yn"));
            course.item("survey_yn", courseList.s("survey_yn"));
            course.item("review_yn", courseList.s("review_yn"));
            course.item("cert_course_yn", courseList.s("cert_course_yn"));
            course.item("cert_complete_yn", courseList.s("cert_complete_yn"));
            course.item("cert_template_id", courseList.s("cert_template_id"));

            // 구 클라우드 데이터에는 합격증(pass) 관련 컬럼이 없을 수 있으므로
            // 값이 비어있을 때는 기본값(N/0)으로 보정합니다.
            String passYn = courseList.s("pass_yn");
            course.item("pass_yn", "".equals(passYn) ? "N" : passYn);
            course.item("pass_cert_template_id", courseList.i("pass_cert_template_id"));
            course.item("complete_no_yn", courseList.s("complete_no_yn"));
            course.item("postfix_cnt", courseList.s("postfix_cnt"));
            course.item("postfix_type", courseList.s("postfix_type"));
            course.item("postfix_ord", courseList.s("postfix_ord"));
            course.item("complete_prefix", courseList.s("complete_prefix"));
            course.item("sort", courseList.s("sort"));
            course.item("allsort", courseList.s("allsort"));
            course.item("reg_date", courseList.s("reg_date"));
            course.item("sale_yn", courseList.s("sale_yn"));
            course.item("display_yn", courseList.s("display_yn"));
            course.item("status", courseList.s("status"));
            course.item("etc1", courseList.s("etc1"));
            course.item("etc2", courseList.s("etc2"));

            course.insert();
            if(newId > 0) {
                courseJobj.put(courseList.s("id"), "" + newId);
            }
        }

        //save courseJobj
        saveMap("LM_COURSE", courseJobj);

        //과정강의섹션등록
        JSONObject sectionJobj = new JSONObject();
        DataSet courseLessonSectionList = j.getDataSet("//course_section_list");
        courseLessonSectionList.sort("course_id");
        while(courseLessonSectionList.next()) {
            courseSection.clear();
            int newId = courseSection.getSequence();

            int courseId = courseJobj.has(courseLessonSectionList.s("course_id")) ? courseJobj.getInt(courseLessonSectionList.s("course_id")) : 0;
            if(0 == courseId) continue;

            courseSection.item("id", newId);
            courseSection.item("course_id", courseId);
            courseSection.item("site_id", 1);
            courseSection.item("section_nm", courseLessonSectionList.s("section_nm"));
            courseSection.item("status", courseLessonSectionList.s("status"));

            courseSection.insert();
            if(newId > 0) {
                sectionJobj.put(courseLessonSectionList.s("id"), "" + newId);
            }

        }

        //save sectionJobj
        saveMap("LM_COURSE_SECTION", sectionJobj);

        //과정강의등록
        DataSet courseLessonList = j.getDataSet("//course_lesson_list");
        courseLessonList.sort("course_id");
        while(courseLessonList.next()) {
            courseLesson.clear();

            int uid = userJobj.has(courseLessonList.s("tutor_id")) ? userJobj.getInt(courseLessonList.s("tutor_id")) : 0;
            int courseId  = courseJobj.has(courseLessonList.s("course_id")) ? courseJobj.getInt(courseLessonList.s("course_id")) : 0;
            int lessonId  = lessonJobj.has(courseLessonList.s("lesson_id")) ? lessonJobj.getInt(courseLessonList.s("lesson_id")) : 0;
            if(0 == courseId || 0 == lessonId) continue;
            int sectionId = sectionJobj.has(courseLessonList.s("section_id")) ? sectionJobj.getInt(courseLessonList.s("section_id")) : 0;

            courseLesson.item("course_id", courseId);
            courseLesson.item("lesson_id", lessonId);
            courseLesson.item("section_id", sectionId);
            courseLesson.item("site_id", 1);
            courseLesson.item("twoway_url", courseLessonList.s("twoway_url"));
            courseLesson.item("host_num", courseLessonList.s("host_num"));
            courseLesson.item("chapter", courseLessonList.s("chapter"));
            courseLesson.item("start_day", courseLessonList.s("start_day"));
            courseLesson.item("period", courseLessonList.s("period"));
            courseLesson.item("start_date", courseLessonList.s("start_date"));
            courseLesson.item("end_date", courseLessonList.s("end_date"));
            courseLesson.item("start_time", courseLessonList.s("start_time"));
            courseLesson.item("end_time", courseLessonList.s("end_time"));
            courseLesson.item("lesson_hour", courseLessonList.d("lesson_hour"));
            courseLesson.item("tutor_id", uid);
            courseLesson.item("progress_yn", courseLessonList.s("progress_yn"));
            courseLesson.item("status", courseLessonList.s("status"));

            courseLesson.insert();
        }

        //수강생등록
        JSONObject courseUserJobj = new JSONObject();
        DataSet courseUserList = j.getDataSet("//course_user_list");
        courseUserList.sort("id");
        while(courseUserList.next()) {
            courseUser.clear();
            int newId = courseUser.getSequence();

            int courseId = courseJobj.has(courseUserList.s("course_id")) ? courseJobj.getInt(courseUserList.s("course_id")) : 0;
            int uid = userJobj.has(courseUserList.s("user_id")) ? userJobj.getInt(courseUserList.s("user_id")) : 0;
            if(0 == courseId || 0 == uid) continue;

            courseUser.item("id", newId);
            courseUser.item("site_id", 1);
            courseUser.item("package_id", courseUserList.s("package_id"));
            courseUser.item("course_id", courseId);
            courseUser.item("user_id", uid);
//            courseUser.item("order_id", courseUserList.s("order_id"));
//            courseUser.item("order_item_id", courseUserList.s("order_item_id"));
            courseUser.item("start_date", courseUserList.s("start_date"));
            courseUser.item("end_date", courseUserList.s("end_date"));
            courseUser.item("renew_cnt", courseUserList.s("renew_cnt"));
            courseUser.item("class", courseUserList.s("class"));
            courseUser.item("tutor_id", courseUserList.s("tutor_id"));
            courseUser.item("grade", courseUserList.s("grade"));
            courseUser.item("progress_ratio", courseUserList.s("progress_ratio"));
            courseUser.item("progress_score", courseUserList.s("progress_score"));
            courseUser.item("exam_value", courseUserList.s("exam_value"));
            courseUser.item("exam_score", courseUserList.s("exam_score"));
            courseUser.item("homework_value", courseUserList.s("homework_value"));
            courseUser.item("homework_score", courseUserList.s("homework_score"));
            courseUser.item("forum_value", courseUserList.s("forum_value"));
            courseUser.item("forum_score", courseUserList.s("forum_score"));
            courseUser.item("etc_value", courseUserList.s("etc_value"));
            courseUser.item("etc_score", courseUserList.s("etc_score"));
            courseUser.item("total_score", courseUserList.s("total_score"));
            courseUser.item("credit", courseUserList.s("credit"));
            courseUser.item("complete_yn", courseUserList.s("complete_yn"));
            courseUser.item("complete_no", courseUserList.s("complete_no"));
            courseUser.item("complete_date", courseUserList.s("complete_date"));
            courseUser.item("fail_reason", courseUserList.s("fail_reason"));
            courseUser.item("close_yn", courseUserList.s("close_yn"));
            courseUser.item("close_date", courseUserList.s("close_date"));
            courseUser.item("close_user_id", courseUserList.s("close_user_id"));
            courseUser.item("change_date", courseUserList.s("change_date"));
            courseUser.item("mod_date", courseUserList.s("mod_date"));
            courseUser.item("reg_date", courseUserList.s("reg_date"));
            courseUser.item("status", courseUserList.s("status"));

            courseUser.insert();
            if(newId > 0) {
                courseUserJobj.put(courseUserList.s("id"), "" + newId);
            }

        }
        //save courseUserJobj
        //saveMap(String tableName, JSONObject data)
        saveMap("LM_COURSE_USER", courseUserJobj);

        //학습등록
        DataSet courseUserLogList = j.getDataSet("//course_user_log_list");
        courseUserLogList.sort("id");
        while(courseUserLogList.next()) {
            courseUserLog.clear();

            int courseUserId = courseUserJobj.has(courseUserLogList.s("course_user_id")) ? courseUserJobj.getInt(courseUserLogList.s("course_user_id")) : 0;
            int courseId = courseJobj.has(courseUserLogList.s("course_id")) ? courseJobj.getInt(courseUserLogList.s("course_id")) : 0;
            int uid = userJobj.has(courseUserLogList.s("user_id")) ? userJobj.getInt(courseUserLogList.s("user_id")) : 0;
            int lessonId = lessonJobj.has(courseUserLogList.s("lesson_id")) ? lessonJobj.getInt(courseUserLogList.s("lesson_id")) : 0;
            if(0 == courseUserId || 0 == courseId || 0 == uid || 0 == lessonId) continue;

            courseUserLog.item("course_user_id", courseUserId);
            courseUserLog.item("user_id", uid);
            courseUserLog.item("course_id", courseId);
            courseUserLog.item("chapter", courseUserLogList.s("chapter"));
            courseUserLog.item("lesson_id", lessonId);
            courseUserLog.item("progress_ratio", courseUserLogList.s("progress_ratio"));
            courseUserLog.item("progress_complte_yn", courseUserLogList.s("progress_complte_yn"));
            courseUserLog.item("user_ip_addr", courseUserLogList.s("user_ip_addr"));
            courseUserLog.item("user_agent", courseUserLogList.s("user_agent"));
            courseUserLog.item("reg_date", courseUserLogList.s("reg_date"));
            courseUserLog.item("status", courseUserLogList.s("status"));
            courseUserLog.item("site_id", 1);

            courseUserLog.insert();

        }

        //수강생진도등록
        DataSet courseProgressList = j.getDataSet("//course_progress_list");
        courseProgressList.sort("course_user_id");
        while(courseProgressList.next()) {
            courseProgress.clear();

            int courseUserId = courseUserJobj.has(courseProgressList.s("course_user_id")) ? courseUserJobj.getInt(courseProgressList.s("course_user_id")) : 0;
            int courseId = courseJobj.has(courseProgressList.s("course_id")) ? courseJobj.getInt(courseProgressList.s("course_id")) : 0;
            int uid = userJobj.has(courseProgressList.s("user_id")) ? userJobj.getInt(courseProgressList.s("user_id")) : 0;
            int lessonId = lessonJobj.has(courseProgressList.s("lesson_id")) ? lessonJobj.getInt(courseProgressList.s("lesson_id")) : 0;
            int changeUserId = lessonJobj.has(courseProgressList.s("change_user_id")) ? lessonJobj.getInt(courseProgressList.s("change_user_id")) : 0;
            if(0 == courseUserId || 0 == courseId || 0 == uid || 0 == lessonId) continue;

            courseProgress.item("course_id", courseId);
            courseProgress.item("lesson_id", lessonId);
            courseProgress.item("chapter", courseProgressList.s("chapter"));
            courseProgress.item("course_user_id", courseUserId);
            courseProgress.item("user_id", uid);
            courseProgress.item("lesson_type", courseProgressList.s("lesson_type"));
            courseProgress.item("study_page", courseProgressList.s("study_page"));
            courseProgress.item("study_time", courseProgressList.s("study_time"));
            courseProgress.item("curr_page", courseProgressList.s("curr_page"));
            courseProgress.item("curr_time", courseProgressList.s("curr_time"));
            courseProgress.item("last_time", courseProgressList.s("last_time"));
            courseProgress.item("paragraph", courseProgressList.s("paragraph"));
            courseProgress.item("ratio", courseProgressList.s("ratio"));
            courseProgress.item("complete_yn", courseProgressList.s("complete_yn"));
            courseProgress.item("complete_date", courseProgressList.s("complete_date"));
            courseProgress.item("view_cnt", courseProgressList.s("view_cnt"));
            courseProgress.item("last_date", courseProgressList.s("last_date"));
            courseProgress.item("change_user_id", changeUserId);
            courseProgress.item("reg_date", courseProgressList.s("reg_date"));
            courseProgress.item("status", courseProgressList.s("status"));
            courseProgress.item("site_id", 1);

            courseProgress.insert();

        }

        //회원동의등록
        DataSet userAgreementList = j.getDataSet("//user_agreement_list");
        userAgreementList.sort("id");
        while(userAgreementList.next()) {
            agreementLog.clear();

            int uid = userJobj.has(userAgreementList.s("user_id")) ? userJobj.getInt(userAgreementList.s("user_id")) : 0;
            if(0 == uid) continue;

            agreementLog.item("site_id", 1);
            agreementLog.item("user_id", uid);
            agreementLog.item("type", userAgreementList.s("type"));
            agreementLog.item("agreement_yn", userAgreementList.s("agreement_yn"));
            agreementLog.item("module", userAgreementList.s("module"));
            agreementLog.item("module_id", userAgreementList.s("module_id"));
            agreementLog.item("reg_date", userAgreementList.s("reg_date"));

            agreementLog.insert();

        }

        //게사판
        JSONObject boardJobj = new JSONObject();
        DataSet boardList = j.getDataSet("//board_list");
        boardList.sort("id");
        while(boardList.next()) {
            board.clear();
            int newId = board.getSequence();

            board.item("id", newId);
            board.item("site_id", 1);
            board.item("code", boardList.s("code"));
            board.item("board_nm", boardList.s("board_nm"));
            board.item("layout", boardList.s("layout"));
            board.item("breadscrumb", boardList.s("breadscrumb"));
            board.item("board_type", boardList.s("board_type"));
            board.item("admin_idx", boardList.s("admin_idx"));
            board.item("auth_list", boardList.s("auth_list"));
            board.item("auth_read", boardList.s("auth_read"));
            board.item("auth_write", boardList.s("auth_write"));
            board.item("auth_reply", boardList.s("auth_reply"));
            board.item("auth_comm", boardList.s("auth_comm"));
            board.item("auth_download", boardList.s("auth_download"));
            board.item("list_num", boardList.i("list_num"));
            board.item("notice_yn", boardList.s("notice_yn"));
            board.item("reply_yn", boardList.s("reply_yn"));
            board.item("delete_yn", boardList.s("delete_yn"));
            board.item("comment_yn", boardList.s("comment_yn"));
            board.item("category_yn", boardList.s("category_yn"));
            board.item("upload_yn", boardList.s("upload_yn"));
            board.item("image_yn", boardList.s("image_yn"));
            board.item("captcha_yn", boardList.s("captcha_yn"));
            board.item("private_yn", boardList.s("private_yn"));
            board.item("allow_type", boardList.s("allow_type"));
            board.item("deny_ext", boardList.s("deny_ext"));
            board.item("header_html", boardList.s("header_html"));
            board.item("footer_html", boardList.s("footer_html"));
            board.item("user_template", boardList.s("user_template"));
            board.item("sort", boardList.i("sort"));
            board.item("reg_date", boardList.s("reg_date"));
            board.item("status", boardList.i("status"));

            board.insert();
            if(newId > 0) {
                boardJobj.put(boardList.s("id"), "" + newId);
                boardJobj.put(boardList.s("id") + "-category_yn", boardList.s("category_yn"));
            }
        }

        //save boardJobj
        //saveMap(String tableName, JSONObject data)
        saveMap("TB_BOARD", boardJobj);

        //게시판 카테고리
        JSONObject boardCategoryJobj = new JSONObject();
        DataSet boardCategoryList = j.getDataSet("//board_category_list");
        boardCategoryList.sort("id");
        while(boardCategoryList.next()) {
            category.clear();
            int newId = category.getSequence();

            int boardId = boardJobj.has(boardCategoryList.s("module_id")) ? boardJobj.getInt(boardCategoryList.s("module_id")) : 0;

            category.item("id", newId);
            category.item("site_id", 1);
            category.item("module", boardCategoryList.s("module"));
            category.item("module_id", boardId);
            category.item("category_nm", boardCategoryList.s("category_nm"));
            category.item("sort", boardCategoryList.i("sort"));
            category.item("status", boardCategoryList.i("status"));

            category.insert();
            if(newId > 0) {
                boardCategoryJobj.put(boardCategoryList.s("id"), "" + newId);
            }
        }

        //save boardCategoryJobj
        //saveMap(String tableName, JSONObject data)
        saveMap("TB_CATEGORY", boardCategoryJobj);

        //게시글
        DataSet postList = j.getDataSet("//post_list");
        postList.sort("id");
        while(postList.next()) {
            post.clear();
            int newId = post.getSequence();

            int boardId = boardJobj.has(postList.s("board_id")) ? boardJobj.getInt(postList.s("board_id")) : 0;
            if(boardId == 0) continue;
            boolean boardCategoryYn = boardJobj.has("" + boardId + "-category_yn") ? "Y".equals(boardJobj.get("" + boardId + "-category_yn")) : false;
            int boardCategoryId = boardCategoryYn && boardCategoryJobj.has(postList.s("category_id")) ? boardCategoryJobj.getInt(postList.s("category_id")) : 0;
            int uid = userJobj.has(postList.s("user_id")) ? userJobj.getInt(postList.s("user_id")) : 0;

            post.item("id", newId);
            post.item("site_id", 1);
            post.item("board_id", boardId);
            post.item("category_id", boardCategoryId);
            post.item("thread", postList.i("thread"));
            post.item("depth", postList.s("depth"));
            post.item("user_id", uid);
            post.item("writer", postList.s("writer"));
            post.item("subject", postList.s("subject"));
            post.item("content", postList.s("content"));
            post.item("youtube_cd", postList.s("youtube_cd"));
            post.item("notice_yn", postList.s("notice_yn"));
            post.item("secret_yn", postList.s("secret_yn"));
            post.item("hit_cnt", postList.i("hit_cnt"));
            post.item("comm_cnt", postList.i("comm_cnt"));
            post.item("recomm_cnt", postList.i("recomm_cnt"));
            post.item("file_cnt", postList.i("file_cnt"));
            post.item("display_yn", postList.s("display_yn"));
            post.item("sort", postList.i("sort"));
            post.item("proc_status", postList.s("proc_status"));
            post.item("mod_date", postList.s("mod_date"));
            post.item("reg_date", postList.s("reg_date"));
            post.item("status", postList.s("status"));

            post.insert();

        }

        //과정게시판
        JSONObject clBoardJobj = new JSONObject();
        DataSet clBoardList = j.getDataSet("//clboard_list");
        clBoardList.sort("id");
        while(clBoardList.next()) {
            clBoard.clear();
            int newId = clBoard.getSequence();

            int courseId = courseJobj.has(clBoardList.s("course_id")) ? courseJobj.getInt(clBoardList.s("course_id")) : 0;

            clBoard.item("id", newId);
            clBoard.item("site_id", 1);
            clBoard.item("course_id", courseId);
            clBoard.item("code", clBoardList.s("code"));
            clBoard.item("board_nm", clBoardList.s("board_nm"));
            clBoard.item("base_yn", clBoardList.s("base_yn"));
            clBoard.item("board_type", clBoardList.s("board_type"));
            clBoard.item("content", clBoardList.s("content"));
            clBoard.item("sort", clBoardList.i("sort"));
            clBoard.item("link", clBoardList.s("link"));
            clBoard.item("write_yn", clBoardList.s("write_yn"));
            clBoard.item("reg_date", clBoardList.s("reg_date"));
            clBoard.item("status", clBoardList.i("status"));

            clBoard.insert();
            if(newId > 0) {
                clBoardJobj.put(clBoardList.s("id"), "" + newId);
            }
        }

        //save clBoardJobj
        //saveMap(String tableName, JSONObject data)
        saveMap("CL_BOARD", clBoardJobj);

        //과정게시글
        DataSet clPostList = j.getDataSet("//clpost_list");
        clPostList.sort("id");
        while(clPostList.next()) {
            clPost.clear();

            int courseId = courseJobj.has(clPostList.s("course_id")) ? courseJobj.getInt(clPostList.s("course_id")) : 0;
            int clBoardId = clBoardJobj.has(clPostList.s("board_id")) ? clBoardJobj.getInt(clPostList.s("board_id")) : 0;
            int courseUserId = courseUserJobj.has(clPostList.s("course_user_id")) ? courseUserJobj.getInt(clPostList.s("course_user_id")) : 0;

            clPost.item("site_id", 1);
            clPost.item("course_id", courseId);
            clPost.item("board_cd", clPostList.s("board_cd"));
            clPost.item("board_id", clBoardId);
            clPost.item("course_user_id", courseUserId);
            clPost.item("thread", clPostList.i("thread"));
            clPost.item("depth", clPostList.s("depth"));
            clPost.item("user_id", clPostList.i("user_id"));
            clPost.item("writer", clPostList.s("writer"));
            clPost.item("subject", clPostList.s("subject"));
            clPost.item("content", clPostList.s("content"));
            clPost.item("point", clPostList.s("point"));
            clPost.item("public_yn", clPostList.s("public_yn"));
            clPost.item("notice_yn", clPostList.s("notice_yn"));
            clPost.item("secret_yn", clPostList.s("secret_yn"));
            clPost.item("hit_cnt", clPostList.i("hit_cnt"));
            clPost.item("comm_cnt", clPostList.i("comm_cnt"));
            clPost.item("file_cnt", clPostList.i("file_cnt"));
            clPost.item("display_yn", clPostList.s("display_yn"));
            clPost.item("proc_status", clPostList.s("proc_status"));
            clPost.item("mod_date", clPostList.s("mod_date"));
            clPost.item("reg_date", clPostList.s("reg_date"));
            clPost.item("status", clPostList.i("status"));

            clPost.insert();

        }

    } else {
        m.jsAlert("파일을 읽는 중 오류가 발생했습니다.");
        m.js("parent.location.href = parent.location.href");
        return;
    }

    m.jsAlert("데이터 이관이 완료 되었습니다.");
    m.js("parent.document.getElementById(\"prog\").style.display = \"none\";");
    return;

}

p.setLayout(ch);
p.setBody("migration.migrate_from_cloud");
p.setVar("p_title", "클라우드 데이터 가져오기");
p.setVar("form_script", f.getScript());

p.setVar("upload_area", true);
p.display();

%>
<%!
public void saveMap(String tableName, JSONObject data) throws Exception {
    String fileDir = "/Users/kyounghokim/IdeaProjects/MalgnLMS/migration/";
    Writer fin = null;
    if(data == null) return;
    try {
        //폴더유무확인
        if (fileDir == null) fileDir = "/tmp";
        File fd = new File(fileDir);
        if (!fd.exists()) {
            fd.mkdirs();
        }
        //파일유무확인
        boolean isExist = true;
        File f = new File(fileDir + "/" + tableName + ".txt");
        if (!f.exists()) isExist = false;
        fin = new OutputStreamWriter(new FileOutputStream(fileDir + "/" + tableName + ".txt", isExist), "UTF-8");
        if(fin == null) throw new IOException("fin is null");
        Iterator<String> i = data.keys(); // key값들을 모두 얻어옴
        while(i.hasNext()) {
            String key = i.next();
            if(!data.has(key)) continue;
            fin.write("prev_id = " + key + " | current_id = " + data.get(key));
            fin.write("\n");
        }
    } catch(UnsupportedEncodingException uee) {
        uee.printStackTrace(System.out);
    } catch(IOException ioe) {
        ioe.printStackTrace(System.out);
    } catch(Exception e) {
        e.printStackTrace(System.out);
    } finally {
        if(fin != null) fin.close();
    }
} //end_func
%>
