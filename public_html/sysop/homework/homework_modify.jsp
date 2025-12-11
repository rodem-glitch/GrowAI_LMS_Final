<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.30

//접근권한
if(!Menu.accessible(73, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
HomeworkDao homework = new HomeworkDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();
CourseModuleDao courseModule = new CourseModuleDao();

//정보
DataSet info = homework.query(
	"SELECT a.*, u.user_nm manager_name "
	+ " FROM " + homework.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ (courseManagerBlock ? " AND a.manager_id IN (-99, " + userId + ")" : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다.");	return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("homework_file"))) {
		homework.item("homework_file", "");
		if(!homework.update("id = " + id)) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFileRoot(m.getUploadPath(info.s("homework_file")));
	}
	return;
}

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리명'");
f.addElement("category_nm", category.getTreeNames(info.i("category_id")), "hname:'카테고리'");
f.addElement("homework_nm", info.s("homework_nm"), "hname:'과제명', required:'Y'");
f.addElement("homework_file", null, "hname:'첨부파일'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	homework.item("category_id", f.get("category_id"));
	homework.item("homework_nm", f.get("homework_nm"));
	homework.item("content", content);
	if(!courseManagerBlock) homework.item("manager_id", f.getInt("manager_id"));
	homework.item("status", f.getInt("status"));

	if(null != f.getFileName("homework_file")) {
		File f1 = f.saveFile("homework_file");
		if(f1 != null) {
			homework.item("homework_file", f.getFileName("homework_file"));
			if(!"".equals(info.s("homework_file"))) m.delFileRoot(m.getUploadPath(info.s("homework_file")));
		}
	}

	if(!homework.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//수정
	if(!info.s("homework_nm").equals(f.get("homework_nm"))) {
		courseModule.item("module_nm", f.get("homework_nm"));
		if(!courseModule.update("site_id = " + siteId + " AND module = 'homework' AND module_id = " + id)) {
			m.jsAlert("기존 과제명을 수정하는 중 오류가 발생했습니다.");
			return;
		}
	}

	m.jsReplace("homework_list.jsp?" + m.qs("id"), "parent");
	return;

}

//포맷팅
info.put("content", m.htt(info.s("content")));
info.put("homework_file_conv", m.encode(info.s("homework_file")));
info.put("homework_file_url", m.getUploadUrl(info.s("homework_file")));
info.put("homework_file_ek", m.encrypt(info.s("homework_file") + m.time("yyyyMMdd")));
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), homework.onoffTypes));


//출력
p.setBody("homework.homework_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(homework.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("courses", courseModule.getCourses("homework", id));
p.setVar("course_cnt", courseModule.getCourseCount("homework", id));
p.setLoop("categories", category.getList(siteId));
p.display();

%>