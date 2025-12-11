<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

DataSet info = certificateTemplate.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("certificate_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("background_file")));

out.print(info.s("content"));
%>