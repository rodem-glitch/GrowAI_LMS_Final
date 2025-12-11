<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FileDao file = new FileDao();

//폼체크
f.addElement("qqfile", null, "hname:'파일', required:'Y', allow:'" + SiteConfig.s("join_userfile_ext") + "'");

//변수
String now = m.time("yyyyMMddHHmmss");

//정보
DataSet info = new DataSet();
info.addRow();

//등록
if(m.isPost() && f.validate()) {
	if(null != f.getFileName("qqfile")) {
		File f1 = f.saveFile("qqfile");
		if(f1 != null) {
			String uploadUrl = m.getUploadUrl(f.getFileName("qqfile"));
			if(null != uploadUrl && !"".equals(uploadUrl)) {

				//파일리사이징
				try {
					String imgPath = m.getUploadPath(f.getFileName("qqfile"));
					String cmd = "convert -resize 500x> " + imgPath + " " + imgPath;
					Runtime.getRuntime().exec(cmd);
				}
				catch(RuntimeException re) { m.errorLog(re.getMessage(), re); }
				catch(Exception e) { m.errorLog(e.getMessage(), e); }


				//등록-정보
				//int tempId = 0 < userId ? userId : m.getRandInt(-2000000, 1990000);
				int tempId = m.getRandInt(-2000000, 1990000);
				int newId = file.getSequence();
				file.item("id", newId);
				file.item("module", "user");
				file.item("module_id", tempId);
				file.item("site_id", siteId);
				file.item("filename", f.getFileName("qqfile"));
				file.item("filetype", f.getFileType("qqfile"));
				file.item("file_uuid", f.get("fileuuid"));
				file.item("filesize", f1.length());
				file.item("realname", f1.getName());
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
					info.put("filename", f.getFileName("qqfile"));
					info.put("k", newId);
					info.put("ek", m.sha256(newId + "_userfile_" + tempId));
				}
			} else {
				info.put("success", "false");
				info.put("error", "파일을 업로드하는 중 오류가 발생했습니다.");
				info.put("reset", "true");
			}
		}
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
String result = info.serialize();
out.print(result.substring(1, result.length() - 1));

%>