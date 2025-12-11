<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.awt.Image,javax.swing.ImageIcon" %>
<%@ include file="init.jsp" %><%
/*
DataSet tempInfo = new DataSet();
tempInfo.addRow();

tempInfo.put("test1-S", f.get("filesize"));
tempInfo.put("test1-I", f.getInt("filesize"));
tempInfo.put("test1-L", );
//tempInfo.put("test2", f.get("mid"));

tempInfo.put("reset", "false");
tempInfo.put("error", "테스트.");
tempInfo.put("success", "false");

//출력
String tempResult = tempInfo.serialize();
out.print(tempResult.substring(1, tempResult.length() - 1));

if(true) return;
*/

//기본키
String mid = f.get("mid");
if("".equals(mid)) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//폼입력
String md = f.get("md", "post");
String allow = f.get("allow", "jpg|jpeg|gif|png|swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra|pdf|hwp|txt|doc|docx|xls|xlsx|ppt|pptx|zip|7z|rar|alz|egg");

//폼체크
f.addElement("filename", null, "hname:'파일', required:'Y', allow:'" + allow + "'");

//변수
String now = m.time("yyyyMMddHHmmss");

//정보
DataSet info = new DataSet();
info.addRow();

//등록
if(m.isPost() && f.validate()) {
	if((100 * 1000 * 1000) < f.getLong("filesize")) {
		info.put("success", "false");
		info.put("error", "100MB를 초과하여 업로드 할 수 없습니다.");
		info.put("reset", "true");
	} else if(null != f.getFileName("filename")) {
		File f1 = f.saveFile("filename");
		if(f1 != null) {
			String uploadUrl = m.getUploadUrl(f.getFileName("filename"));
			if(null != uploadUrl && !"".equals(uploadUrl)) {

				//파일리사이징
				try {
					if(f.getFileName("filename").matches("(?i)^.+\\.(jpg|jpeg|png|gif|bmp)$")) {
						Image img = new ImageIcon(m.getUploadPath(f.getFileName("filename"))).getImage();
						if(700 < img.getWidth(null)) {
							String imgPath = m.getUploadPath(f.getFileName("filename"));
							String cmd = "convert -resize 1100x> " + imgPath + " " + imgPath;
							Runtime.getRuntime().exec(cmd);
						}
					}
				}
				catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
				catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }

				//등록-정보
				int newId = file.getSequence();
				file.item("id", newId);
				file.item("module", md);
				file.item("module_id", mid);
				file.item("site_id", siteId);
				file.item("filename", f.getFileName("filename"));
				file.item("filetype", f.getFileType("filename"));
				file.item("filesize", f1.length());
				file.item("realname", f1.getName());
				file.item("file_uuid", f.get("fileuuid"));
				file.item("main_yn", "N");
				file.item("reg_date", now);
				file.item("status", 1);

				if(!file.insert()) {
					info.put("success", "false");
					info.put("error", "파일을 등록하는 중 오류가 발생했습니다.");
					info.put("reset", "true");
				} else {
					info.put("success", "true");
					info.put("url", uploadUrl);
					info.put("k", newId);
					info.put("ek", m.sha256(newId + "_" + md + "file_" + mid));
				}
			} else {
				info.put("success", "false");
				info.put("error", "파일을 업로드하는 중 오류가 발생했습니다.");
				info.put("reset", "true");
			}
		}
	} else {
		info.put("success", "false");
		info.put("error", "해당 파일 정보가 없습니다.");
		info.put("reset", "true");
	}
} else {
	if(null != f.errMsg && !"".equals(f.errMsg)) {
		info.put("success", "false");
		info.put("error", f.errMsg);
		info.put("reset", "true");
	} else {
		info.put("success", "false");
		info.put("error", "올바른 접근이 아닙니다.");
		info.put("reset", "true");
	}
}

//출력
response.setContentType("application/json;charset=utf-8");
String result = info.serialize();
out.print(result.substring(1, result.length() - 1));

%>