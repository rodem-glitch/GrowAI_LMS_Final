<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
TutorDao tutor = new TutorDao();
FileDao file = new FileDao();

//정보
DataSet info = user.query(
    " SELECT a.*, t.tutor_nm, t.name_en, t.attached, t.tutor_file, t.ability, t.university, t.major, t.introduce, t.bank_nm, t.bank_account "
    + " FROM " + user.table + " a "
    + " LEFT JOIN " + tutor.table + " t ON a.id = t.user_id AND t.status != -1 "
    + " WHERE a.id = " + uid + " AND a.site_id = " + siteId + " AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 회원정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("sleep_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("sleep_date")));
info.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("conn_date")));
info.put("status_conv", m.getItem(info.s("status"), user.statusList));

//포맷팅
if(0 < info.i("dept_id")) {
    info.put("dept_nm_conv", userDept.getNames(info.i("dept_id")));
} else {
    info.put("dept_nm", "[미소속]");
    info.put("dept_nm_conv", "[미소속]");
}
info.put("tutor_file_conv", m.encode(info.s("tutor_file")));
info.put("tutor_file_url", m.getUploadUrl(info.s("tutor_file")));
info.put("tutor_file_ek", m.encrypt(info.s("tutor_file") + m.time("yyyyMMdd")));
info.put("user_kind_conv", m.getItem(info.s("user_kind"), user.kinds));
info.put("email_yn_conv", m.getItem(info.s("email_yn"), user.receiveYn));
info.put("sms_yn_conv", m.getItem(info.s("sms_yn"), user.receiveYn));
info.put("status_conv", m.getItem(info.s("status"), user.statusList));
info.put("display_yn_conv", info.b("display_yn") ? "노출" : "숨김");
info.put("gender_conv", m.getItem(info.s("gender"), user.genders));
info.put("birthday_conv", m.time("yyyy.MM.dd", info.s("birthday")));
info.put("mobile_conv", info.s("mobile"));
user.maskInfo(info);

//파일
DataSet files = file.getFileList(m.parseInt(uid), "user", true);
while(files.next()) {
    files.put("ext", file.getFileIcon(files.s("filename")));
    files.put("ek", m.encrypt(files.s("id")));
    files.put("file_url", m.getUploadUrl(files.s("filename")));
    files.put("class", -1 < files.s("filetype").indexOf("image/") ? "image01" : "");
}

//기록-개인정보조회
if(!isBlindUser) _log.add("V", "회원정보 상세조회", 1, "이러닝 운영", info);

//출력
p.setLayout(ch);
p.setBody("crm.user_view");
p.setVar("p_title", "회원정보 상세조회");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("tab_user", "current");
p.setVar(info);
p.setLoop("files", files);
p.setVar("SITE_CONFIG", SiteConfig.getArr(new String[] {"user_etc_", "join_"}));
p.setLoop("dept_list", userDept.getList(siteId));
p.display();

%>