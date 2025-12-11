<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(74, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ForumDao forum = new ForumDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();
CourseModuleDao courseModule = new CourseModuleDao();

//정보
DataSet info = forum.query(
	"SELECT a.*, u.user_nm manager_name "
	+ " FROM " + forum.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ (courseManagerBlock ? " AND a.manager_id IN (-99, " + userId + ")" : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("forum_file"))) {
		forum.item("forum_file", "");
		if(!forum.update("id = " + id)) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFileRoot(m.getUploadPath(info.s("forum_file")));
	}
	return;
}

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리명'");
f.addElement("category_nm", category.getTreeNames(info.i("category_id")), "hname:'카테고리'");
f.addElement("forum_nm", info.s("forum_nm"), "hname:'토론명', required:'Y'");
f.addElement("content", null, "hname:'토론내용'");
f.addElement("forum_file", null, "hname:'첨부파일'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	forum.item("category_id", f.get("category_id"));
	forum.item("forum_nm", f.get("forum_nm"));
	forum.item("content", f.get("content"));
	if(!courseManagerBlock) forum.item("manager_id", f.getInt("manager_id"));
	forum.item("status", f.getInt("status"));

	if(null != f.getFileName("forum_file")) {
		File f1 = f.saveFile("forum_file");
		if(f1 != null) {
			forum.item("forum_file", f.getFileName("forum_file"));
			if(!"".equals(info.s("forum_file"))) m.delFileRoot(m.getUploadPath(info.s("forum_file")));
		}
	}

	if(!forum.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//수정
	if(!info.s("forum_nm").equals(f.get("forum_nm"))) {
		courseModule.item("module_nm", f.get("forum_nm"));
		if(!courseModule.update("site_id = " + siteId + " AND module = 'forum' AND module_id = " + id)) {
			m.jsAlert("기존 토론명을 수정하는 중 오류가 발생했습니다.");
			return;
		}
	}

	m.jsReplace("forum_list.jsp?" + m.qs("id"), "parent");
	return;

}
info.put("content", m.htt(info.s("content")));
info.put("forum_file_conv", m.encode(info.s("forum_file")));
info.put("forum_file_path", siteDomain + m.getUploadUrl(info.s("forum_file")));
info.put("forum_file_ek", m.encrypt(info.s("forum_file") + m.time("yyyyMMdd")));
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), forum.onoffTypes));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));


//출력
p.setBody("forum.forum_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(forum.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("courses", courseModule.getCourses("forum", id));
p.setVar("course_cnt", courseModule.getCourseCount("forum", id));
p.setLoop("categories", category.getList(siteId));
p.display();

%>