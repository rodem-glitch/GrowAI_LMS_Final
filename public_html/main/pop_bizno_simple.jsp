<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%@ page import="malgnsoft.json.*" %><%

f.addElement("biz_no", null, "hname:'사업자등록번호', required:'Y'");

boolean isCorrect = false;
if(m.isPost() && f.validate()) {
    String baseUrl = "https://api.odcloud.kr/api/nts-businessman/v1/status";
    String serviceKey = "5fb2K5BEb1bpBntg3p1z7ynVC2Kr1%2BzZrO9BehRS33viKskvCgmw9szNG6YzOZnTbUTFTO%2FS2pG%2BwI7pe6e8Xw%3D%3D";
    //String serviceKey = "vNcSMi4OL4E6Ad4qHc7VPtuJpfqI%2BoC9cOBGJaZr1EyNdzrhwfcIU0F%2FTCgdzFCAQanrwptjYNmxgAuzOgguXA%3D%3D";
    String returnType = "JSON";
    String bizno[] = { f.get("biz_no") };

    JSONObject requestData = new JSONObject();
    requestData.put("b_no", bizno);

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
            isCorrect = !"".equals(binfo.s("b_stt_cd"));
            result = isCorrect ? binfo.s("b_stt") + " / " + binfo.s("tax_type") : binfo.s("tax_type");
        }
    } else {
        result = "사업자등록 정보 조회 중 오류가 발생했습니다.";
    }
    p.setVar("result", result);
}

//출력
p.setLayout("blank");
p.setBody("main.pop_bizno_simple");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("is_correct", isCorrect);

p.display();
%>