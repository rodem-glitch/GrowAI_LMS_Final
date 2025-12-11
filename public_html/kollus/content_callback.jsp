<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String uploadFileKey = m.rs("upload_file_key");
String mediaContentKey = m.rs("media_content_key");
String type = m.rs("update_type"); //등록:channel_join, 삭제:

m.log("kollus_file", "type : " + type + ", upload_file_key : " + uploadFileKey + ", media_content_key : " + mediaContentKey);

if("".equals(uploadFileKey) || "".equals(mediaContentKey)) {
    out.print("기본키는 반드시 지정하여야 합니다.");
    return;
}
if(!"channel_join".equals(type)) {
    out.print("채널 추가 신호만 처리합니다.");
    return;
}

//객체
KollusFileDao kollusFile = new KollusFileDao();

//정보
DataSet info = kollusFile.find("upload_file_key = ?", new String[] { uploadFileKey });
if(!info.next()) { out.print("해당 파일이 없습니다."); return; }

kollusFile.item("media_content_key", mediaContentKey);
kollusFile.update("upload_file_key = '" + info.s("upload_file_key") + "'");

%>