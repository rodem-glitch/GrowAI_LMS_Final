<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%@ page import="malgnsoft.json.*" %><%

MCal mcal = new MCal(); mcal.yearRange = 50;

f.addElement("biz_no", null, "hname:'사업자등록번호', required:'Y'");
f.addElement("ceo_nm", null, "hname:'대표자성명', required:'Y'");
f.addElement("open_year", null, "hname:'개업일시', required:'Y'");
f.addElement("open_month", null, "hname:'개업일시', required:'Y'");
f.addElement("open_day", null, "hname:'개업일시', required:'Y'");


boolean isCorrect = false;
if(m.isPost() && f.validate()) {
    String baseUrl = "https://api.odcloud.kr/api/nts-businessman/v1/validate";
    String serviceKey = "5fb2K5BEb1bpBntg3p1z7ynVC2Kr1%2BzZrO9BehRS33viKskvCgmw9szNG6YzOZnTbUTFTO%2FS2pG%2BwI7pe6e8Xw%3D%3D";
    String returnType = "JSON";
    String bizno = f.get("biz_no");
    String name = f.get("ceo_nm");
    String date = f.get("open_year") + f.get("open_month") + f.get("open_day");

    DataSet info = new DataSet();
    info.addRow();
    info.put("b_no", bizno.replaceAll("-", ""));
    info.put("p_nm", name);
    info.put("start_dt", date);

    JSONObject requestData = new JSONObject();
    requestData.put("businesses", info);

    Http http = new Http();
    http.setUrl(baseUrl + "?serviceKey=" + serviceKey + "&returnType=" + returnType);
    http.setHeader("Content-Type", "application/json");
    http.setData(requestData.toString());

    Json ret = new Json(http.send("POST"));
    String result = "";

    if("OK".equals(ret.get("//status_code"))) {
        DataSet binfo = ret.getDataSet("//data");
        if(!binfo.next()) {
            result = "해당하는 사업자정보가 없습니다.";
        } else {
            if(!"01".equals(binfo.s("valid"))) {
                result = "해당하는 사업자정보가 없습니다.";
            } else {
                Json j = new Json(binfo.s("status"));
                result = j.get("//b_stt") + " / " + j.get("//tax_type");
                isCorrect = true;
            }
        }
    } else {
        result = "사업자등록 정보 조회 중 오류가 발생했습니다.";
    }
    p.setVar("result", result);
}

//출력
p.setLayout("blank");
p.setBody("main.pop_bizno");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("is_correct", isCorrect);

p.setLoop("years", mcal.getYears(m.addDate("Y", -49, sysToday, "yyyy")));
p.setLoop("months", mcal.getMonths());
p.setLoop("days", mcal.getDays());

p.display();
%>