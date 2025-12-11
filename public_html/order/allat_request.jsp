<%@ page contentType="text/html; charset=euc-kr" %><%@ include file="../init.jsp" %><%

//변수
String sResultCd = request.getParameter("allat_result_cd");
String sResultMsg = request.getParameter("allat_result_msg");
String sEncData = request.getParameter("allat_enc_data");

//로그
m.log("allat_request", "sResultCd:" + sResultCd + "\nsResultMsg:" + sResultMsg + "\nsEncData:" + sEncData);

if("".equals(sResultCd) || "".equals(sResultMsg) || "".equals(sEncData)) {
    m.jsError("해당 정보가 없습니다.");
    return;
}

//출력
out.println("<script>");
out.println("if(window.opener != undefined) {");
out.println("	opener.result_submit('" + m.htt(sResultCd) + "','" + m.htt(sResultMsg) + "','" + m.htt(sEncData) + "');");
out.println("	window.close();");
out.println("} else {");
out.println("	parent.result_submit('" + m.htt(sResultCd) + "','" + m.htt(sResultMsg) + "','" + m.htt(sEncData) + "');");
out.println("}");
out.println("</script>");

%>