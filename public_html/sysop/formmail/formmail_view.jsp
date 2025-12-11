<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(115, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
FormmailDao formmail = new FormmailDao();
FileDao file = new FileDao();
UserDao user = new UserDao(isBlindUser);

//정보
DataSet info = formmail.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; };
String mobile = "";
if(!"".equals(info.s("mobile"))) mobile = info.s("mobile");
info.put("mobile_conv", mobile);
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.i("status"), formmail.statusList));
user.maskInfo(info);

//기록-개인정보조회
if(info.size() > 0 && !isBlindUser) _log.add("V", "게시판목록", info.size(), "이러닝 운영", info);

//목록-파일
DataSet files = file.getFileList(id, "formmail");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}

//출력
p.setLayout(ch);
p.setBody("formmail.formmail_view");
p.setVar("p_title", "이메일문의관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("files", files);

p.display();

%>