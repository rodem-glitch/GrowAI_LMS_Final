<%@ page contentType="application/json; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

//기본키
String mid = f.get("mid");
String ek = f.get("ek");
if("".equals(mid) || "".equals(ek)) { result.put("rst_message", "기본키는 반드시 지정해야 합니다."); result.print(); return; }

//폼입력
String md = f.get("md", "post");

//제한
if(!ek.equals(m.encrypt("LMS@FILE_" + md + "_ID" + mid + "_LIST_" + sysToday))) { result.print(); return; }

//목록-파일
DataSet temp = new DataSet();
DataSet files = file.getFileList(userId, "user", true);
while(files.next()) {
	temp.addRow();
	temp.put("name", files.s("filename"));
	temp.put("uuid", files.s("file_uuid"));
	temp.put("size", files.s("filesize"));
	temp.put("image_block", -1 < files.s("filetype").indexOf("image/"));
	temp.put("thumbnailUrl", temp.b("image_block") ? m.getUploadUrl(files.s("filename")) : "/common/fine-uploader/placeholders/not_available-malgn.png");
}

//출력
result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", temp.size());
result.put("rst_data", temp);
result.print();

%>