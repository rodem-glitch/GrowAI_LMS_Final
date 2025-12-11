<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int kind = m.ri("kind");
int cuid = 0;
int lid = 0;
int chapter = 0;
String sysopKey = "";
if(!"".equals(m.rs("uservalues"))) {
    DataSet val = new Json().decode(m.rs("uservalues"));
    if(val.next()) {
        cuid = val.i("uservalue0");
        lid = val.i("uservalue1");
        chapter = val.i("uservalue2");
        sysopKey = val.s("uservalue3");
    }
}

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteinfo.s("access_token"), siteinfo.s("security_key"), siteinfo.s("custom_key"));

//검사-관리자
boolean isSysop = false;
if(0 > cuid && -99 == lid && sysopKey.equals(m.encrypt(siteId + sysToday + (-1 * cuid), "SHA-256"))) {
    DataSet uinfo = user.find("site_id = ? AND id = ? AND user_kind IN ('C', 'D', 'A', 'S') AND status = 1", new Integer[] { siteId, (-1 * cuid) });
    if(uinfo.next()) isSysop = true;
}

//변수
int result = 1;
int expDate = 0;
String message = "";
DataSet ret = new DataSet();
ret.addRow();
ret.put("kind", kind);

//처리
if(isSysop) {
    //관리자
    expDate = m.getUnixTime(sysToday + "235959");
    if(1 == kind) ret.put("expiration_date", expDate);

} else {
    //정보
    DataSet info = courseUser.find("id = ? AND status = 1", new Object[] {cuid});
    DataSet cpinfo = courseProgress.query(
        " SELECT a.study_time, l.total_time, c.limit_ratio_yn, c.limit_ratio "
        + " FROM " + courseProgress.table + " a "
        + " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
        + " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status = 1 "
        + " WHERE a.course_user_id = ? AND a.lesson_id = ?"
        , new Object[] {cuid, lid}
    );
    if(info.next() && cpinfo.next()) {
        expDate = m.getUnixTime(info.s("end_date") + "235959");

        if(1 == kind) ret.put("expiration_date", expDate);

        if(cpinfo.b("limit_ratio_yn")) {
            int remainTime = (int)(cpinfo.i("total_time") * 60 * cpinfo.d("limit_ratio") - cpinfo.d("study_time"));
            if(1 > remainTime) {
                result = 0;
                message = _message.get("alert.classroom.over_study");
            } else if(1 == kind) {
                ret.put("expiration_playtime", remainTime);
            }

            m.log("kollus_play"
                , "LIMIT_RATIO : " + cpinfo.s("limit_ratio_yn")
                + " / total_time : " + (cpinfo.i("total_time") * 60)
                + " / limit_time : " + (int)(cpinfo.i("total_time") * 60 * cpinfo.d("limit_ratio"))
                + " / study_time : " + (cpinfo.i("study_time"))
                + " / remain_time : " + (int)(cpinfo.i("total_time") * 60 * cpinfo.d("limit_ratio") - cpinfo.d("study_time"))
            );
        }
    } else {
        result = 0;
        message = "해당 수강생 정보가 없습니다.";
    }
}

ret.put("result", result);
if(1 > result) ret.put("message", message);

//출력
response.setHeader("X-Kollus-UserKey", siteinfo.s("custom_key"));
String srl = ret.serialize();
String res = "{\"data\": " + srl.substring(1, srl.length() - 1) + (0 < expDate ? ", \"exp\": " + expDate : "") + "}";
out.print(kollus.getWebToken(res));

m.log("kollus_play", "RESPONSE : " + res);

%>