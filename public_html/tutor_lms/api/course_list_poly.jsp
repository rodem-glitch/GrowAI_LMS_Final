<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- `project` 화면의 "담당과목" 목록에서, 학사 View(LMS_COURSE_VIEW) 데이터를 조회하여 통합 형식으로 반환합니다.
//- 기존 course_list.jsp(LM_COURSE)와 병합하여 사용합니다.

String year = m.rs("year");
int limit = m.ri("cnt", 1000);

//학사 시스템 API 호출
malgnsoft.util.Http http = new malgnsoft.util.Http("https://e-poly.kopo.ac.kr/main/vpn_test.jsp");
http.setParam("tb", "COM.LMS_COURSE_VIEW");
http.setParam("cnt", "" + limit);
String jsonRaw = http.send("POST");

malgnsoft.db.DataSet rs = new malgnsoft.db.DataSet();

if(jsonRaw != null && !jsonRaw.trim().equals("")) {
    String trimmed = jsonRaw.trim();
    if(trimmed.startsWith("[")) {
        try { rs = malgnsoft.util.Json.decode(trimmed); } catch(Exception e) { /* ignore */ }
    } else {
        //텍스트 형식 파싱 (key: value)
        String[] lines = jsonRaw.split("\n");
        java.util.Map<String, String> currentRow = new java.util.HashMap<String, String>();
        for(String line : lines) {
            if(line.contains(":") && !line.startsWith("--")) {
                int sep = line.indexOf(":");
                String key = line.substring(0, sep).trim();
                String val = line.substring(sep + 1).trim().replaceAll(",\\s*$", ""); // 끝의 쉼표 제거
                if(!"".equals(key)) {
                    if(currentRow.containsKey(key)) { rs.addRow(currentRow); currentRow = new java.util.HashMap<String, String>(); }
                    currentRow.put(key, val);
                }
            }
        }
        if(!currentRow.isEmpty()) rs.addRow(currentRow);
    }
}

//통합 형식으로 변환
malgnsoft.db.DataSet list = new malgnsoft.db.DataSet();

while(rs.next()) {
    String openYear = rs.s("open_year");
    
    //년도 필터 (빈 값이면 전체)
    if(!"".equals(year) && !year.equals(openYear)) continue;
    
    java.util.Map<String, Object> row = new java.util.HashMap<String, Object>();
    
    //공통 필드
    row.put("source", "poly");
    row.put("id", rs.s("course_code"));
    row.put("course_cd", rs.s("course_code"));
    row.put("course_nm", rs.s("course_name"));
    row.put("year", openYear);
    
    //학사 View 전용 필드
    row.put("dept_code", rs.s("dept_code"));
    row.put("dept_name", rs.s("dept_name"));
    row.put("grad_code", rs.s("grad_code"));
    row.put("grad_name", rs.s("grad_name"));
    row.put("bunban_code", rs.s("bunban_code"));
    row.put("curriculum_code", rs.s("curriculum_code"));
    row.put("curriculum_name", rs.s("curriculum_name"));
    row.put("grade", rs.s("grade"));
    row.put("open_term", rs.s("open_term"));
    row.put("category", rs.s("category"));
    row.put("visible", rs.s("visible"));
    row.put("course_ename", rs.s("course_ename"));
    
    //API 전용 필드는 빈값
    row.put("program_id", 0);
    row.put("program_nm_conv", "");
    row.put("course_type_conv", "");
    row.put("onoff_type_conv", "");
    row.put("period_conv", "");
    row.put("student_cnt", 0);
    row.put("status_label", "-");
    
    list.addRow(row);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
