<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//폼체크
f.addElement("course_key", "course_cd", "hname:'과정키', required:'Y'");
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost()) {
    
    //변수
    DataSet list = new DataSet();
    String[] courseKeys = null;
    String[] loginIds = null;
    StringBuilder sb = new StringBuilder();
    
    //엑셀파일
    File f1 = f.saveFile("file");
    if(f1 != null) {
        DataSet records = new DataSet();
        String path = m.getUploadPath(f.getFileName("file"));
        try {
            records = new ExcelReader(path).getDataSet(1);
        } catch(Exception e) {
            m.jsAlert("호환되지 않거나 손상된 파일입니다.");
            return;
        }
        if(!"".equals(path)) m.delFileRoot(path);
        
        //포맷팅
        courseKeys = new String[records.size()];
        loginIds = new String[records.size()];
        int idx = 0;
        
        while(records.next()) {
            String lidTrim = records.s("col1").trim();
            if(!"".equals(records.s("col0")) && !"".equals(lidTrim)) {
                courseKeys[idx] = records.s("col0");
                loginIds[idx] = lidTrim;
                //m.p(idx + ". " + records.s("col0"));
                list.addRow();
                list.put("__idx", ++idx);
                list.put("course_key", records.s("col0"));
                list.put("login_id", lidTrim);
                list.put("start_date", (8 != records.s("col2").length() ? m.time("yyyyMMdd") : m.time("yyyyMMdd", records.s("col2"))));
                list.put("end_date", (8 != records.s("col3").length() ? m.time("yyyyMMdd") : m.time("yyyyMMdd", records.s("col3"))));
                list.put("reg_date", (14 != records.s("col4").length() ? m.time("yyyyMMddHHmmss") : m.time("yyyyMMddHHmmss", records.s("col4"))));
                list.put("complete_yn", ("Y".equals(records.s("col5")) || "N".equals(records.s("col5")) ? records.s("col5") : "N"));
                list.put("progress_ratio", records.d("col6"));
                list.put("progress_score", records.d("col7"));
                list.put("total_score", records.d("col7"));
            } else {
                courseKeys[idx] = "-99";
                loginIds[idx] = "empty" + Malgn.getUniqId();
            }
        }
    } else {
        m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
        return;
    }
    
    
    //제한-과정키 없음
    if(courseKeys == null || 1 > courseKeys.length) {
        m.jsAlert("과정키가 없습니다.");
        return;
    }
    
    //변수
    HashMap<String, Integer> courseIdList = new HashMap<String, Integer>();
    HashMap<String, Integer> courseCreditList = new HashMap<String, Integer>();
    HashMap<String, Integer> userIdList = new HashMap<String, Integer>();
    
    //정보-과정
    DataSet clist = course.find(f.get("course_key") + " IN ('" + m.join("', '", courseKeys) + "') AND site_id = " + siteId);
    while(clist.next()) {
        courseIdList.put(clist.s(f.get("course_key")), clist.i("id"));
        courseCreditList.put(clist.s(f.get("course_key")), clist.i("credit"));
    }
    
    //정보-회원
    DataSet ulist = user.find("login_id IN ('" + m.join("', '", loginIds) + "') AND site_id = " + siteId);
    while(ulist.next()) {
        userIdList.put(ulist.s("login_id"), ulist.i("id"));
    }
    
    //수강생등록
    int success = 0;
    int failed = 0;
    
    courseUser.item("site_id", siteId);
    courseUser.item("package_id", 0);
    courseUser.item("order_id", 0);
    courseUser.item("order_item_id", 0);
    courseUser.item("grade", 1);
    
    courseUser.item("exam_value", 0);
    courseUser.item("exam_score", 0);
    courseUser.item("homework_value", 0);
    courseUser.item("homework_score", 0);
    courseUser.item("forum_value", 0);
    courseUser.item("forum_score", 0);
    courseUser.item("etc_value", 0);
    courseUser.item("etc_score", 0);
    
    courseUser.item("close_yn", "N");
    courseUser.item("close_date", "");
    courseUser.item("close_user_id", 0);
    courseUser.item("mod_date", m.time("yyyyMMddHHmmss"));
    courseUser.item("status", 1);
    
    sb.append("전체 목록: ").append(list.size()).append("개<br>");
    list.first();
    while(list.next()) {
        out.print(list.i("__idx") + ". ");
        int cid = courseIdList.containsKey(list.s("course_key")) ? courseIdList.get(list.s("course_key")) : 0;
        int uid = userIdList.containsKey(list.s("login_id")) ? userIdList.get(list.s("login_id")) : 0;
        if(1 > cid || 1 > uid) {
            sb.append("cid 또는 uid가 등록되지 않음 -> index : ").append(list.i("__idx")).append(" / courseKey : ").append(list.s("course_key")).append(" / login_id : ").append(list.s("login_id")).append("<br>");
            failed++;
            continue;
        }
        
        sb.append("cid: ").append(cid).append(", uid: ").append(uid).append(", result: ");
        
        //중복검사
        if(0 < courseUser.findCount("id = " + cid + " AND user_id = " + uid + " AND site_id = " + siteId)) {
            sb.append("해당 데이터가 이미 존재함<br>");
            failed++;
            continue;
        }
        
        int newId = courseUser.getSequence();
        courseUser.item("id", newId);
        courseUser.item("user_id", uid);
        courseUser.item("course_id", cid);
        
        courseUser.item("start_date", list.s("start_date"));
        courseUser.item("end_date", list.s("end_date"));

        // RENEW_CNT 컬럼이 NOT NULL인 환경에서도 마이그레이션 등록이 실패하지 않도록
        // 별도 연장 이력이 없는 경우 기본값 0으로 세팅합니다.
        courseUser.item("renew_cnt", 0);
        courseUser.item("progress_ratio", list.d("progress_ratio"));
        courseUser.item("progress_score", list.d("progress_score"));
        courseUser.item("total_score", list.d("total_score"));
        
        courseUser.item("credit", (courseCreditList.containsKey(list.s("course_key")) ? courseCreditList.get(list.s("course_key")).intValue() : 0));
        courseUser.item("complete_yn", list.s("complete_yn"));
        courseUser.item("complete_no", (list.b("complete_yn") ? m.time("yyyy", list.s("end_date")) + "-1-" + newId : ""));
        courseUser.item("complete_date", (list.b("complete_yn") ? list.s("end_date") + "000000" : ""));
        courseUser.item("reg_date", list.s("start_date") + "000000");
        
        if(!courseUser.insert()) {
            sb.append("실패<br>");
            failed++;
        } else {
            sb.append("성공<br>");
            success++;
        }
        
    }
    
    m.jsAlert(success + "건 성공 / " + failed + "건 실패");
    m.js("try { parent.document.write('" + sb.toString() + "'); } catch(e) { }");
    return;
}

//출력
p.setLayout("sysop");
p.setBody("migration.course_user_insert");
p.setVar("p_title", "수강생일괄등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("tab_course_user", "current");

p.display();

%>
