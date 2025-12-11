<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!"125.129.123.211".equals(userIp)) return;

//객체
CourseDao dao = new CourseDao();
dao.d(out);

//변수
String[] tables = new String[] { "LM_COURSE=>course_file", "LM_FORUM=>forum_file", "LM_FORUM_POST=>post_file", "LM_HOMEWORK=>homework_file", "LM_HOMEWORK_USER=>user_file", "LM_LESSON=>lesson_file", "LM_LIBRARY=>library_file", "LM_QUESTION=>question_file,item1_file,item2_file,item3_file,item4_file,item5_file", "LM_WEBTV=>webtv_file", "TB_BANNER=>banner_file", "TB_FREEPASS=>freepass_file", "TB_SITE=>certificate_file,course_file,certificate_multi_file", "TB_TUTOR=>tutor_file", "TB_UDS_LOG=>fax_file,vxml_file", "TB_USER=>user_file", "TB_FILE=>filename", "CL_FILE=>filename" };

String[] keys = new String[] { "LM_COURSE=>ID,COURSE_NM,REG_DATE,STATUS", "LM_FORUM=>ID,FORUM_NM,REG_DATE,STATUS", "LM_FORUM_POST=>ID,FORUM_ID,COURSE_ID,COURSE_USER_ID,USER_ID,SUBJECT,REG_DATE,STATUS", "LM_HOMEWORK=>HOMEWORK_NM,REG_DATE,STATUS", "LM_HOMEWORK_USER=>HOMEWORK_ID,COURSE_USER_ID,COURSE_ID,USER_ID,SUBJECT,REG_DATE,STATUS", "LM_LESSON=>ID,CONTENT_ID,LESSON_NM,REG_DATE,STATUS", "LM_LIBRARY=>ID,LIBRARY_NM,REG_DATE,STATUS", "LM_QUESTION=>ID,CATEGORY_ID,QUESTION,REG_DATE,STATUS", "LM_WEBTV=>ID,LESSON_ID,AUDIO_ID,WEBTV_NM,REG_DATE,STATUS", "TB_BANNER=>ID,BANNER_NM,REG_DATE,STATUS", "TB_FREEPASS=>ID,FREEPASS_NM,REG_DATE,STATUS", "TB_MANUAL=>ID,MANUAL_NM,REG_DATE,STATUS", "TB_SITE=>ID,DOMAIN,DOMAIN2,SITE_NM,COMPANY_NM,REG_DATE,STATUS", "TB_TUTOR=>USER_ID,TUTOR_NM,STATUS", "TB_UDS_LOG=>CMID,UMID", "TB_USER=>ID,LOGIN_ID,USER_NM,REG_DATE,STATUS", "TB_FILE=>ID,MODULE,MODULE_ID,MAIN_YN,FILE_NM,REALNAME,FILESIZE,FILETYPE,REG_DATE", "CL_FILE=>ID,MODULE,MODULE_ID,MAIN_YN,FILE_NM,REALNAME,FILESIZE,FILETYPE,REG_DATE" };

//폼입력
String mode = m.rs("mode");
int pnum = m.ri("p");
if(1 > pnum) pnum = 1;

if(!"".equals(mode)) {
    String[] fields = m.split(",", m.getItem(mode, tables));
    DataSet list = dao.query("SELECT " + m.getItem(mode, keys) + "," + m.getItem(mode, tables) + " FROM " + mode + " WHERE site_id = " + siteId + " LIMIT " + ((pnum - 1) * 60000) + ", 60000");

    if(0 < list.size()) {
        while(list.next()) {
            for(String field : fields) {
                list.put(field + "_conv", !"".equals(list.s(field)) ? m.getUploadUrl(list.s(field)) : "");
            }
        }

        /*
        ExcelWriter ex = new ExcelWriter(response, mode + ".xls");
        ex.setData(list);
        ex.write();
        */
    } else {
        m.jsAlert("해당 정보가 없습니다.");
    }
    return;

}

for(String table : tables) {
    String[] temp = m.split("=>", table);
    out.println("<a href=\"filedata_list.jsp?mode=" + temp[0] + "&p=1\" target=\"sysfrm\">" + temp[0] + " 1</a> <a href=\"filedata_list.jsp?mode=" + temp[0] + "&p=2\" target=\"sysfrm\">2</a> <a href=\"filedata_list.jsp?mode=" + temp[0] + "&p=3\" target=\"sysfrm\">3</a> <a href=\"filedata_list.jsp?mode=" + temp[0] + "&p=4\" target=\"sysfrm\">4</a> <a href=\"filedata_list.jsp?mode=" + temp[0] + "&p=5\" target=\"sysfrm\">5</a> <br>");
}

out.println("<iframe name=\"sysfrm\" id=\"sysfrm\" frameborder=\"1\" width=\"100%\" height=\"500\" src=\"\"></iframe>");

%>