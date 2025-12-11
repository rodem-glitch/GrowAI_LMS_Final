<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ManualDao manual = new ManualDao();
FileDao file = new FileDao();

//정보
DataSet info = manual.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }
info.put("manual_file_ext", file.getFileExt(info.s("manual_file")));
info.put("pdf_block", "pdf".equals(info.s("manual_file_ext").toLowerCase()));
info.put("manual_file_url", m.getUploadUrl(info.s("manual_file")));

//파일
DataSet files = file.find("module = 'manual' AND module_id = " + id + " AND status = 1");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}

//출력
p.setLayout("pop");
p.setBody("manual.manual_view");
p.setVar("p_title", info.s("manual_nm"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.display();

%>