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
                    String val = line.substring(sep + 1).trim().replaceAll(",\\s*$", ""); // 끝의 쉼표 제거
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

    // 학사 데이터 정규화 (LMS_COURSE_VIEW 25개 필드 전체 매핑)
    resultList.first();
    while(resultList.next()) {
        resultList.put("source_type", "haksa");
        
        // ===== LMS_COURSE_VIEW 25개 필드 정규화 (대소문자 모두 처리) =====
        // 1. CATEGORY - 강좌형태
        String category = resultList.s("CATEGORY");
        if("".equals(category)) category = resultList.s("category");
        resultList.put("haksa_category", category);
        
        // 2. DEPT_NAME - 학과/전공 이름
        String deptName = resultList.s("DEPT_NAME");
        if("".equals(deptName)) deptName = resultList.s("dept_name");
        resultList.put("haksa_dept_name", deptName);
        
        // 3. WEEK - 주차
        String week = resultList.s("WEEK");
        if("".equals(week)) week = resultList.s("week");
        resultList.put("haksa_week", week);
        
        // 4. OPEN_TERM - 학기
        String openTerm = resultList.s("OPEN_TERM");
        if("".equals(openTerm)) openTerm = resultList.s("open_term");
        resultList.put("haksa_open_term", openTerm);
        
        // 5. COURSE_CODE - 강좌코드
        String courseCode = resultList.s("COURSE_CODE");
        if("".equals(courseCode)) courseCode = resultList.s("course_code");
        resultList.put("haksa_course_code", courseCode);
        
        // 6. VISIBLE - 강좌 폐강 여부
        String visible = resultList.s("VISIBLE");
        if("".equals(visible)) visible = resultList.s("visible");
        resultList.put("haksa_visible", visible);
        
        // 7. STARTDATE - 강좌시작일
        String startdate = resultList.s("STARTDATE");
        if("".equals(startdate)) startdate = resultList.s("startdate");
        resultList.put("haksa_startdate", startdate);
        
        // 8. BUNBAN_CODE - 분반코드
        String bunbanCode = resultList.s("BUNBAN_CODE");
        if("".equals(bunbanCode)) bunbanCode = resultList.s("bunban_code");
        resultList.put("haksa_bunban_code", bunbanCode);
        
        // 9. GRADE - 학년
        String grade = resultList.s("GRADE");
        if("".equals(grade)) grade = resultList.s("grade");
        resultList.put("haksa_grade", grade);
        
        // 10. GRAD_NAME - 단과대학 이름
        String gradName = resultList.s("GRAD_NAME");
        if("".equals(gradName)) gradName = resultList.s("grad_name");
        resultList.put("haksa_grad_name", gradName);
        
        // 11. DAY_CD - 강의 요일
        String dayCd = resultList.s("DAY_CD");
        if("".equals(dayCd)) dayCd = resultList.s("day_cd");
        resultList.put("haksa_day_cd", dayCd);
        
        // 12. CLASSROOM - 강의실 정보
        String classroom = resultList.s("CLASSROOM");
        if("".equals(classroom)) classroom = resultList.s("classroom");
        resultList.put("haksa_classroom", classroom);
        
        // 13. CURRICULUM_CODE - 과목구분 코드
        String curriculumCode = resultList.s("CURRICULUM_CODE");
        if("".equals(curriculumCode)) curriculumCode = resultList.s("curriculum_code");
        resultList.put("haksa_curriculum_code", curriculumCode);
        
        // 14. COURSE_ENAME - 강좌명(영문)
        String courseEname = resultList.s("COURSE_ENAME");
        if("".equals(courseEname)) courseEname = resultList.s("course_ename");
        resultList.put("haksa_course_ename", courseEname);
        
        // 15. TYPE_SYLLABUS - 강의계획서 구분
        String typeSyllabus = resultList.s("TYPE_SYLLABUS");
        if("".equals(typeSyllabus)) typeSyllabus = resultList.s("type_syllabus");
        resultList.put("haksa_type_syllabus", typeSyllabus);
        
        // 16. OPEN_YEAR - 연도
        String openYear = resultList.s("OPEN_YEAR");
        if("".equals(openYear)) openYear = resultList.s("open_year");
        resultList.put("haksa_open_year", openYear);
        
        // 17. DEPT_CODE - 학과/전공 코드
        String deptCode = resultList.s("DEPT_CODE");
        if("".equals(deptCode)) deptCode = resultList.s("dept_code");
        resultList.put("haksa_dept_code", deptCode);
        
        // 18. COURSE_NAME - 강좌명(한글)
        String courseName = resultList.s("COURSE_NAME");
        if("".equals(courseName)) courseName = resultList.s("course_name");
        resultList.put("haksa_course_name", courseName);
        
        // 19. GROUP_CODE - 학부/대학원 구분
        String groupCode = resultList.s("GROUP_CODE");
        if("".equals(groupCode)) groupCode = resultList.s("group_code");
        resultList.put("haksa_group_code", groupCode);
        
        // 20. ENDDATE - 강좌종료일
        String enddate = resultList.s("ENDDATE");
        if("".equals(enddate)) enddate = resultList.s("enddate");
        resultList.put("haksa_enddate", enddate);
        
        // 21. ENGLISH - 영문 강좌 여부
        String english = resultList.s("ENGLISH");
        if("".equals(english)) english = resultList.s("english");
        resultList.put("haksa_english", english);
        
        // 22. HOUR1 - 강의 시간
        String hour1 = resultList.s("HOUR1");
        if("".equals(hour1)) hour1 = resultList.s("hour1");
        resultList.put("haksa_hour1", hour1);
        
        // 23. CURRICULUM_NAME - 과목구분 이름
        String curriculumName = resultList.s("CURRICULUM_NAME");
        if("".equals(curriculumName)) curriculumName = resultList.s("curriculum_name");
        resultList.put("haksa_curriculum_name", curriculumName);
        
        // 24. GRAD_CODE - 단과대학 코드
        String gradCode = resultList.s("GRAD_CODE");
        if("".equals(gradCode)) gradCode = resultList.s("grad_code");
        resultList.put("haksa_grad_code", gradCode);
        
        // 25. IS_SYLLABUS - 강의계획서 존재여부
        String isSyllabus = resultList.s("IS_SYLLABUS");
        if("".equals(isSyllabus)) isSyllabus = resultList.s("is_syllabus");
        resultList.put("haksa_is_syllabus", isSyllabus);
        
        // ===== 기존 호환 필드 (목록 화면용) =====
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
