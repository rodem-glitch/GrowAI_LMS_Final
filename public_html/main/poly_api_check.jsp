<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%
/* Polytechnic API Dashboard - Smart Parser (JSON or Text) with Control UI */
String[] tables = {
    "COM.LMS_MEMBER_VIEW", 
    "COM.LMS_PROFESSOR_VIEW", 
    "COM.LMS_STUDENT_VIEW", 
    "COM.LMS_COURSE_VIEW", 
    "COM.LMS_LECTPLAN_VIEW", 
    "COM.LMS_LECTPLAN_NCS_VIEW"
};

String selectedTable = m.rs("tb", tables[0]);
int limit = m.ri("cnt", 10);

malgnsoft.util.Http http = new malgnsoft.util.Http("https://e-poly.kopo.ac.kr/main/vpn_test.jsp");
http.setParam("tb", selectedTable);
http.setParam("cnt", "" + limit);
String jsonRaw = http.send("POST");

malgnsoft.db.DataSet rs = new malgnsoft.db.DataSet();
String statusMsg = "";

if(jsonRaw != null && !jsonRaw.trim().equals("")) {
    String trimmed = jsonRaw.trim();
    if(trimmed.startsWith("[")) {
        try { rs = malgnsoft.util.Json.decode(trimmed); } catch(Exception e) { statusMsg = "JSON Error: " + e.getMessage(); }
    } else {
        String[] lines = jsonRaw.split("\n");
        Map<String, String> currentRow = new HashMap<String, String>();
        for(String line : lines) {
            if(line.contains(":") && !line.startsWith("--")) {
                int sep = line.indexOf(":");
                String key = line.substring(0, sep).trim();
                String val = line.substring(sep + 1).trim();
                if(!"".equals(key)) {
                    if(currentRow.containsKey(key)) { rs.addRow(currentRow); currentRow = new HashMap<String, String>(); }
                    currentRow.put(key, val);
                }
            }
        }
        if(!currentRow.isEmpty()) rs.addRow(currentRow);
        statusMsg = "Converted from text format.";
    }
} else { statusMsg = "No data received. Check VPN."; }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <title>폴리텍 학사 API 통합 연동 확인</title>
    <style>
        body { font-family: sans-serif; background-color: #f4f7f9; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); }
        h1 { color: #1a3353; font-size: 24px; margin-bottom: 25px; border-left: 5px solid #0056b3; padding-left: 15px; }
        .nav-tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 20px; border-bottom: 1px solid #e1e4e8; padding-bottom: 15px; }
        .nav-tabs a { text-decoration: none; padding: 10px 15px; background: #f8f9fa; color: #666; border-radius: 6px; font-size: 13px; font-weight: bold; border: 1px solid #e1e4e8; transition: all 0.2s; }
        .nav-tabs a.active { background: #0056b3; color: #fff; border-color: #0056b3; }
        
        /* Control Panel */
        .controls { background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 25px; display: flex; align-items: center; gap: 20px; border: 1px solid #eee; }
        .control-group { display: flex; align-items: center; gap: 10px; }
        .control-group label { font-size: 14px; font-weight: bold; color: #555; }
        .control-group select, .control-group input { padding: 8px 12px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; }
        .btn-refresh { background: #0056b3; color: #fff; border: none; padding: 9px 20px; border-radius: 5px; font-weight: bold; cursor: pointer; transition: background 0.2s; }
        .btn-refresh:hover { background: #004494; }

        .status-bar { padding: 10px 20px; background: #e7f3ff; color: #0052a3; font-size: 13px; border-radius: 5px; margin-bottom: 20px; }
        .table-wrapper { width: 100%; overflow-x: auto; border: 1px solid #e1e4e8; border-top: 2px solid #1a3353; border-radius: 4px; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6; font-size: 12px; white-space: nowrap; }
        td { padding: 10px 12px; border-bottom: 1px solid #eee; font-size: 13px; color: #444; }
        tr:hover { background-color: #f8fbff; }
    </style>
</head>
<body>
<div class="container">
    <h1>학사 연동 API 통합 확인 대시보드</h1>

    <form method="get" class="controls">
        <div class="control-group">
            <label>대상 테이블:</label>
            <select name="tb">
                <% for(String tb : tables) { %>
                    <option value="<%= tb %>" <%= selectedTable.equals(tb) ? "selected" : "" %>><%= tb.replace("COM.LMS_", "") %></option>
                <% } %>
            </select>
        </div>
        <div class="control-group">
            <label>조회 개수 (cnt):</label>
            <input type="number" name="cnt" value="<%= limit %>" min="1" max="1000" style="width: 80px;">
        </div>
        <button type="submit" class="btn-refresh">데이터 불러오기</button>
    </form>

    <div class="status-bar">
        현재 테이블: <b><%= selectedTable %></b> / 조회 개수: <b><%= limit %>개 요청</b> / 실제 결과: <b><%= rs.size() %>개</b> / 상태: <b><%= statusMsg %></b>
    </div>

    <div class="table-wrapper">
        <% if(rs.size() > 0) { %>
            <table>
                <thead>
                    <tr>
                        <% 
                        rs.first();
                        java.util.Map fMap = (java.util.Map)rs.getRow();
                        if(fMap != null) { for(Object key : fMap.keySet()) { %> <th><%= key %></th> <% } } 
                        %>
                    </tr>
                </thead>
                <tbody>
                    <% rs.first(); do { java.util.Map row = (java.util.Map)rs.getRow(); if(row != null) { %>
                        <tr><% for(Object val : row.values()) { %> <td><%= val != null ? val.toString() : "" %></td> <% } %></tr>
                    <% } } while(rs.next()); %>
                </tbody>
            </table>
        <% } else { %>
            <div style="padding:50px; text-align:center; color:#999; font-style:italic;">조회된 데이터가 없습니다. cnt 값을 높여보거나 VPN 연결을 확인해 주세요.</div>
        <% } %>
    </div>

    <div style="margin-top:20px; border:1px solid #ddd; border-radius:8px; overflow:hidden;">
        <div style="background:#eee; padding:8px 15px; font-size:12px; font-weight:bold; cursor:pointer;" onclick="var s=document.getElementById('raw').style; s.display=s.display=='none'?'block':'none';">▼ 서버 응답 원문 (상세 디버깅용)</div>
        <textarea id="raw" style="display:none; width:100%; height:150px; padding:15px; border:none; font-family:monospace; font-size:12px; background:#fafafa; border-top:1px solid #ddd;" readonly><%= jsonRaw %></textarea>
    </div>
</div>
</body>
</html>
