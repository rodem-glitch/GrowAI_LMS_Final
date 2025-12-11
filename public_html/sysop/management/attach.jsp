<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//폼입력
String module = m.rs("md", "post");

int moduleId = m.ri("mid");

String allow = m.rs("allow", "image,media,file");

//객체
ClFileDao file = new ClFileDao();
ClPostDao post = new ClPostDao();

//삭제
if("del".equals(m.rs("mode")) && m.ri("id") > 0) {

	DataSet info = file.get(m.ri("id"));
	if(!info.next()) {
		m.jsError("해당 정보가 없습니다.");
		return;
	}
	if(file.delete(info.i("id"))) {
		if(!"".equals(info.s("filename"))) m.delFileRoot(m.getUploadPath(info.s("filename")));
	}
	m.jsReplace("attach.jsp?" + m.qs("id, mode"));
	return;
}

//대표이미지변경
if("mod".equals(m.rs("mode")) && m.ri("id") > 0) {
	DataSet info = file.get(m.ri("id"));
	if(!info.next()) {
		m.jsError("해당 정보가 없습니다.");
		return;
	}
	if(-1 != file.execute("UPDATE " + file.table + " SET main_yn = 'N' WHERE module = '" + module + "' AND module_id = '" + moduleId + "'")) {
		file.item("main_yn", "Y");
		if(!file.update()) { }
	}
	m.jsReplace("attach.jsp?" + m.qs("id, mode"));
	return;
}

//게시물에 파일종류 업데이트
if(module.equals("post") && moduleId > 0) post.updateFileCount(moduleId);

//대표이미지존재검사
boolean exists = file.findCount("module = '" + module + "' AND module_id = '" + moduleId + "' AND main_yn = 'Y'") == 1;

//목록
DataSet list = file.query(
	"SELECT a.* FROM " + file.table + " a"
	+ " WHERE a.module = '" + module + "' AND a.module_id = '" + moduleId + "'"
	+ " ORDER BY a.id ASC"
);

//포멧팅
int no = 0;
while(list.next()) {
	boolean isImage = list.s("filename").toLowerCase().matches("^(.+)\\.(jpg|jpeg|gif|png)$");
	if(!exists && isImage) { //대표이미지가 없는경우 첫 번째 이미지를 자동지정
		file.execute("UPDATE " + file.table + " SET main_yn = 'Y' WHERE id = " + list.i("id"));
		list.put("main_yn", "Y");
		exists = true;
	}
	list.put("__idx", ++no);
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("checked", "Y".equals(list.s("main_yn")) ? "checked" : "");
	list.put("ext", file.getFileIcon(list.s("filename")));
	list.put("ek", m.encrypt(list.s("id")));
	list.put("filename_conv", m.urlencode(Base64Coder.encode(list.s("filename"))));
	list.put("fileurl", m.getUploadUrl(list.s("filename")));
	list.put("is_img", isImage);
}

//파일타입
Hashtable<String, String> types = new Hashtable<String, String>();
types.put("image", "false"); types.put("media", "false"); types.put("file", "false");
String[] allows = !"".equals(allow) ? allow.split("\\,") : null;
if(null != allows) {
	for(int i=0; i<allows.length; i++) if(types.containsKey(allows[i])) types.put(allows[i], "true");
}

//출력
p.setLayout("blank");
p.setBody("management.attach");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("del_query", m.qs("id, mode"));
p.setVar("mod_query", m.qs("id, mode"));

p.setLoop("list", list);
p.setVar("use_img", (String)types.get("image"));
p.setVar("use_movie", (String)types.get("media"));
p.setVar("use_file", (String)types.get("file"));
p.setVar("use_desc", 1 != m.ri("nodesc"));
p.display();

%>