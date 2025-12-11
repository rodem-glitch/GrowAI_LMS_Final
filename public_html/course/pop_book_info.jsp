<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int id = m.ri("id");
if(id == 0) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

BookDao book = new BookDao();
DataSet info = book.find("id = " + id); 
if(!info.next()) { m.jsErrClose(_message.get("alert.common.nodata")); return; }
//info.put("book_img_url", Config.getDataUrl() + "/file/" + siteinfo.i("id") + "/book/" + info.s("id") + "_book_img");
//info.put("book_img_url", m.getUploadUrl(info.s("book_img")));
if(!"".equals(info.s("book_img"))) info.put("book_img_url", m.getUploadUrl(info.s("book_img")));
//출력
p.setLayout("blank");
p.setBody("course.pop_book_info");
p.setVar(info);
p.display();

%>