<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int cid = m.ri("cid");

if (userKind=="") {
    userKind = "A";
}

DataSet list = null;
if(!error) {
    //객체
    CourseDao course = new CourseDao();
    CourseUserDao courseUser = new CourseUserDao();
    CourseLessonDao courseLesson = new CourseLessonDao();
    CourseProgressDao courseProgress = new CourseProgressDao();
    ContentDao content = new ContentDao();
    LessonDao lesson = new LessonDao();

    CourseTutorDao courseTutor = new CourseTutorDao();
    TutorDao tutor = new TutorDao();


    //정보
    DataSet cinfo = course.find("id = " + cid + " AND status != -1 AND site_id = " + siteId);
    if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
    cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
    cinfo.put("offline_block", "F".equals(cinfo.s("onoff_type")));

    DataSet types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.types2 : lesson.catenoidTypes2);
    if("N".equals(cinfo.s("onoff_type")))  {
        types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes);
    } else if("F".equals(cinfo.s("onoff_type"))) {
        types = m.arr2loop(lesson.offlineTypes);
    }

    //정보-강사
    DataSet tinfo = courseTutor.query(
            "SELECT a.*, t.tutor_nm "
                    + " FROM " + courseTutor.table + " a "
                    + " INNER JOIN " + tutor.table + " t ON t.user_id = a.user_id "
                    + " WHERE a.course_id = " + cid + ""
            , 1
    );
    if(!tinfo.next()) {
        tinfo.addRow();
        tinfo.put("user_id", 0);
    }

    //목록
    ListManager lm = new ListManager();
    //lm.d(out);
    lm.setRequest(request);
    lm.setListNum(f.getInt("s_listnum", 20));
    lm.setTable(lesson.table + " a LEFT JOIN " + content.table + " c ON c.id = a.content_id AND c.status = 1");
    lm.setFields("a.*, c.content_nm");
    lm.addWhere("a.status = 1");
    lm.addWhere("a.use_yn = 'Y'");
    lm.addWhere("a.site_id = " + siteId + "");

    String type = cinfo.s("onoff_type");
    if("B".equals(type)) { //혼합
        lm.addWhere("a.onoff_type != 'T'");
    } else { //온라인/오프라인 과정
        lm.addWhere("a.onoff_type = '" + type + "'");
    }

    if("C".equals(userKind)) lm.addWhere("(a.onoff_type = 'F' OR c.manager_id = " + userId + ")");
    lm.addWhere("NOT EXISTS ( SELECT 1 FROM " + courseLesson.table + " WHERE course_id = " + cid + " AND lesson_id = a.id )");
    lm.addSearch("a.content_id", f.get("s_content"));
    lm.addSearch("a.lesson_type", f.get("s_type"));
    if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
    else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
        lm.addSearch("a.lesson_nm, a.author, a.start_url, c.content_nm", f.get("s_keyword"), "LIKE");
    }
    lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.content_id desc, a.sort asc, a.id desc");

    //포멧팅
    list = lm.getDataSet();
    while(list.next()) {
        list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
        list.put("moblie_block", !"".equals(list.s("mobile_a")) || !"".equals(list.s("mobile_i")));
        list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
        list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), lesson.onoffTypes));
        list.put("total_time_conv", m.nf(list.i("total_time")));
        list.put("online_block", "N".equals(list.s("onoff_type")));
        list.put("content_nm_conv", 0 < list.i("content_id") ? list.s("content_nm") : "[미지정]");
    }
}

//출력
apiLog.printList(out, _ret, list);
%>