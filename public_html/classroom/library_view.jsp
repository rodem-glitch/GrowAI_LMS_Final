<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
LibraryDao library = new LibraryDao();
FileDao file = new FileDao();

//정보
DataSet info = library.find("status = 1 AND id = " + id + " AND site_id = " + siteId);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
info.put("content_conv", m.nl2br(info.s("content")));
info.put("library_file_ek", m.encrypt(info.s("id") + m.time("yyyyMMdd")));
info.put("library_file_ext", file.getFileIcon(info.s("library_file")));
info.put("library_link_conv", (0 > info.s("library_link").indexOf("//") ? "http://" : "") + info.s("library_link"));

//출력
p.setLayout(ch);
p.setBody("classroom.library_view");
p.setVar("list_query", m.qs("id"));

p.setVar(info);
p.display();

%>