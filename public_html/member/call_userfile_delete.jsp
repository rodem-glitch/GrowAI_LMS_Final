<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDao user = new UserDao();
FileDao file = new FileDao();

//변수
DataSet rinfo = new DataSet();
rinfo.addRow();
boolean isError = false;

//기본키
String key = m.rs("k", f.get("k"));
String ek = m.rs("ek", f.get("ek"));
if("".equals(key) || "".equals(ek)) {
	rinfo.put("success", "false");
	rinfo.put("error", "기본키는 반드시 지정해야 합니다.");
	isError = true;
}

//정보
DataSet info = file.find("id = ? AND module = 'user' AND site_id = ? ORDER BY id DESC", new String[] {key, siteId + ""}, 1);
if(!isError && !info.next()) {
	rinfo.put("success", "false");
	rinfo.put("error", "해당 정보가 없습니다.");
	isError = true;
}
if(!isError && !ek.equals(m.sha256(key + "_userfile_" + info.s("module_id")))) {
	rinfo.put("success", "false");
	rinfo.put("error", "올바른 접근이 아닙니다.");
	isError = true;
}

//삭제-회원정보
user.item("user_file", "");
if(!isError && 0 < userId && !user.update("id = " + userId + " AND user_file != '' AND site_id = " + siteId)) {
	rinfo.put("success", "false");
	rinfo.put("error", "회원정보를 수정하는 중 오류가 발생했습니다.");
	isError = true;
}

//삭제-파일정보
file.item("status", -1);
if(!isError && !file.update("id = " + key + " AND module = 'user' AND site_id = " + siteId)) {
	rinfo.put("success", "false");
	rinfo.put("error", "파일정보를 수정하는 중 오류가 발생했습니다.");
	isError = true;
}

//삭제-파일
if(!isError) {
	m.delFileRoot(m.getUploadPath(info.s("filename")));
	rinfo.put("success", "true");
}

//출력
response.setContentType("application/json;charset=utf-8");
String result = rinfo.serialize();
out.print(result.substring(1, result.length() - 1));

%>