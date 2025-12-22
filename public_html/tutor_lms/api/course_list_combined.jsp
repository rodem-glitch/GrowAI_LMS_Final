<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 담당과목 화면에서 "학사 탭"과 "프리즘 탭"을 분리하여 보여주기 위함입니다.
//- 프리즘 탭은 관리자 과정운영 기준(43건)으로 맞추고, 학사 탭은 폴리텍 뷰테이블 전체를 보여줍니다.

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
SubjectDao subject = new SubjectDao();

String tab = m.rs("tab"); // "prism" 또는 "haksa"
if("".equals(tab)) tab = "prism"; // 기본값: 프리즘

String year = m.rs("year");
String keyword = m.rs("s_keyword");
String today = m.time("yyyyMMdd");

DataSet resultList = new DataSet();
String message = "";

//==============================================================================
// 프리즘 탭: 관리자 과정운영 기준 (43건 맞춤)
//==============================================================================
if("prism".equals(tab)) {
    String where = "";
    ArrayList<Object> params = new ArrayList<Object>();

    if(!"".equals(year) && !"전체".equals(year)) {
        where += " AND c.year = ? ";
        params.add(year);
    }
    if(!"".equals(keyword)) {
        where += " AND (c.course_nm LIKE ? OR s.course_nm LIKE ?) ";
        params.add("%" + keyword + "%");
        params.add("%" + keyword + "%");
    }

    // 왜: 관리자 과정운영과 동일한 기준으로 43건을 맞춤
    // - LM_COURSE_TUTOR 조인 제거 (모든 과목 노출)
    // - display_yn = 'Y' 조건 추가 (노출 허용된 것만)
    try {
        resultList = course.query(
            " SELECT c.id, c.course_cd, c.course_nm, c.course_type, c.onoff_type, c.year, c.status, c.display_yn "
            + " , c.study_sdate, c.study_edate, c.request_sdate, c.request_edate "
            + " , s.course_nm program_nm "
            + " , (SELECT COUNT(*) FROM " + courseUser.table + " cu WHERE cu.course_id = c.id AND cu.status IN (1,3)) student_cnt "
            + " FROM " + course.table + " c "
            + " LEFT JOIN " + subject.table + " s ON s.id = c.subject_id AND s.status != -1 "
            + " WHERE c.site_id = " + siteId + " AND c.status != -1 AND c.display_yn = 'Y' "
            + where
            + " ORDER BY c.id DESC "
            , params.toArray()
        );
    } catch(Exception e) {
        message = "[PErr:" + e.getMessage() + "]";
    }

    // 데이터 정규화
    resultList.first();
    while(resultList.next()) {
        resultList.put("source_type", "prism");
        resultList.put("course_nm_conv", resultList.s("course_nm"));
        resultList.put("onoff_type_conv", m.getItem(resultList.s("onoff_type"), course.onoffTypes));
        
        String ss = resultList.s("study_sdate");
        String se = resultList.s("study_edate");
        resultList.put("period_conv", (!"".equals(ss) && !"".equals(se)) ? (m.time("yyyy.MM.dd", ss) + " - " + m.time("yyyy.MM.dd", se)) : "상시");
        
        String statusLabel = "대기";
        if(!"".equals(ss) && !"".equals(se)) {
            if(0 <= m.diffDate("D", ss, today) && 0 <= m.diffDate("D", today, se)) statusLabel = "학습기간";
            else if(0 < m.diffDate("D", se, today)) statusLabel = "종료";
        }
        resultList.put("status_label", statusLabel);
    }
    
    message = "성공 (프리즘:" + resultList.size() + "건)" + message;
}

//==============================================================================
// 학사 탭: 폴리텍 COM.LMS_COURSE_VIEW 테이블
//==============================================================================
else if("haksa".equals(tab)) {
    malgnsoft.util.Http http = new malgnsoft.util.Http("https://e-poly.kopo.ac.kr/main/vpn_test.jsp");
    http.setParam("tb", "COM.LMS_COURSE_VIEW"); // COURSE_VIEW 테이블 사용
    http.setParam("cnt", "500"); // 전체 조회
    String jsonRaw = http.send("POST");

    if(jsonRaw != null && !jsonRaw.trim().equals("")) {
        String trimmed = jsonRaw.trim();
        
        // 스마트 파서: JSON 또는 텍스트 형식 모두 처리 (poly_api_check.jsp와 동일)
        if(trimmed.startsWith("[")) {
            // JSON 배열 형식
            try {
                resultList = malgnsoft.util.Json.decode(trimmed);
            } catch(Exception e) {
                message = "[JSON Error:" + e.getMessage() + "]";
            }
        } else {
            // 텍스트 형식 (key: value 라인 파싱)
            String[] lines = jsonRaw.split("\n");
            java.util.Map<String, String> currentRow = new java.util.HashMap<String, String>();
            for(String line : lines) {
                if(line.contains(":") && !line.startsWith("--")) {
                    int sep = line.indexOf(":");
                    String key = line.substring(0, sep).trim();
                    String val = line.substring(sep + 1).trim();
                    if(!"".equals(key)) {
                        if(currentRow.containsKey(key)) {
                            resultList.addRow(currentRow);
                            currentRow = new java.util.HashMap<String, String>();
                        }
                        currentRow.put(key, val);
                    }
                }
            }
            if(!currentRow.isEmpty()) resultList.addRow(currentRow);
        }
    }

    // 학사 데이터 정규화 (스프레드시트 기준 필드 매핑)
    resultList.first();
    while(resultList.next()) {
        resultList.put("source_type", "haksa");
        
        // 강좌코드: COURSE_CODE
        String courseCode = resultList.s("COURSE_CODE");
        if("".equals(courseCode)) courseCode = resultList.s("course_code");
        
        // 강좌명: COURSE_NAME
        String courseName = resultList.s("COURSE_NAME");
        if("".equals(courseName)) courseName = resultList.s("course_name");
        
        // 학과명: DEPT_NAME
        String deptName = resultList.s("DEPT_NAME");
        if("".equals(deptName)) deptName = resultList.s("dept_name");
        
        // 강좌형태: CATEGORY
        String category = resultList.s("CATEGORY");
        if("".equals(category)) category = resultList.s("category");
        
        // 연도+학기: OPEN_YEAR, OPEN_TERM
        String openYear = resultList.s("OPEN_YEAR");
        if("".equals(openYear)) openYear = resultList.s("open_year");
        String openTerm = resultList.s("OPEN_TERM");
        if("".equals(openTerm)) openTerm = resultList.s("open_term");
        
        // 폐강여부: VISIBLE (Y=정상, N=폐강)
        String visible = resultList.s("VISIBLE");
        if("".equals(visible)) visible = resultList.s("visible");
        
        // 분반코드: BUNBAN_CODE
        String bunbanCode = resultList.s("BUNBAN_CODE");
        if("".equals(bunbanCode)) bunbanCode = resultList.s("bunban_code");
        
        resultList.put("id", "H_" + courseCode + "_" + bunbanCode);
        resultList.put("course_cd", courseCode);
        resultList.put("course_id_conv", courseCode);
        resultList.put("course_nm", courseName);
        resultList.put("course_nm_conv", courseName);
        resultList.put("program_nm_conv", !"".equals(deptName) ? deptName : "-");
        resultList.put("course_type_conv", !"".equals(category) ? category : "-");
        resultList.put("onoff_type_conv", "학사");
        resultList.put("period_conv", !"".equals(openYear) ? (openYear + "-" + openTerm + "학기") : "-");
        resultList.put("status_label", "Y".equals(visible) ? "학습기간" : "종료");
        resultList.put("student_cnt", 0); // 학사 데이터에 수강생 수 없음
    }
    
    message = "성공 (학사:" + resultList.size() + "건)";
}

// 결과 출력
result.put("rst_code", "0000");
result.put("rst_message", message);
result.put("rst_count", resultList.size());
result.put("rst_data", resultList);
result.print();

%>
