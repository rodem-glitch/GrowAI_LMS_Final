<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_layout.jsp" %><%

//접근권한
if(!Menu.accessible(45, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
FileDao file = new FileDao();

//삭제
if("del".equals(m.rs("mode")) && m.ri("id") > 0) {

	DataSet info = file.get(m.ri("id"));
	if(!info.next()) {
		m.jsError("해당 정보가 없습니다.");
		return;
	}
	if(file.delete(info.i("id"))) {
		if(!"".equals(info.s("realname"))) {
			m.delFileRoot(dataDir + "/file/" + info.s("realname"));
		} else {
			m.delFileRoot(m.getUploadPath(info.s("filename")));
		}
	}
	m.jsReplace("layout_attach.jsp?" + m.qs("id, mode"));
	return;
}

//목록
DataSet list = file.query(
	"SELECT a.* FROM " + file.table + " a "
	+ " WHERE a.module = 'image' "
	+ " ORDER BY a.id ASC"
);

//포멧팅
int no = 0;
while(list.next()) {
	boolean isImage = list.s("filename").toLowerCase().matches("^(.+)\\.(jpg|jpeg|gif|png)$");

	list.put("__idx", ++no);
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("ext", file.getFileIcon(list.s("filename")));
	list.put("ek", m.encrypt(list.s("id")));
	//list.put("ek", m.encrypt(list.s("id") + m.time("yyyyMMdd")));
	list.put("filename_conv", m.urlencode(Base64Coder.encode(list.s("filename"))));
	list.put("fileurl", m.getUploadUrl(list.s("filename")));
}

//출력
p.setLayout("pop");
p.setBody("design.layout_attach");
p.setVar("p_title", "첨부 이미지 관리");
p.setVar("query", m.qs());

p.setLoop("list", list);

p.display();

%>