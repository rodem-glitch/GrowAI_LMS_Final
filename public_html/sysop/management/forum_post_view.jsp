<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int fid = m.ri("fid");
int cuid = m.ri("cuid");
if(id == 0 || cuid == 0 || fid == 0 || courseId == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ForumUserDao forumUser = new ForumUserDao();
ForumPostDao forumPost = new ForumPostDao();
UserDao user = new UserDao();

//정보-토론참여
DataSet finfo = forumUser.query(
	"SELECT a.*, c.module_nm, e.user_nm, e.login_id "
	+ ", d.course_nm, d.year, d.step "
	+ " FROM " + forumUser.table + " a"
	+ " INNER JOIN " + courseUser.table + " b ON a.course_user_id = b.id AND b.status IN (1,3)"
	+ " INNER JOIN " + courseModule.table + " c ON "
		+ " a.forum_id = c.module_id AND c.status = 1 AND c.module = 'forum' AND c.course_id = " + courseId + " "
	+ " INNER JOIN " + course.table + " d ON a.course_id = d.id "
	+ " LEFT JOIN " + user.table + " e ON a.user_id = e.id "
	+ " WHERE a.course_user_id = " + cuid + " AND a.forum_id = " + fid + " AND b.course_id = " + courseId + " AND a.status = 1"
);
if(!finfo.next()) { m.jsErrClose("해당 참여 정보가 없습니다."); return; }
finfo.put("confirm_str", "Y".equals(finfo.s("confirm_yn")) ? "평가완료" : "미평가");

//정보
DataSet info = forumPost.find("id = " + id + " AND status = 1 AND forum_id = " + fid + " AND course_user_id = " + cuid + "");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }
info.put("post_file_conv", m.encode(info.s("post_file")));
info.put("post_file_url", m.getUploadUrl(info.s("post_file")));
info.put("post_file_ek", m.encrypt(info.s("post_file") + m.time("yyyyMMdd")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));

//이전다음글
DataSet prev = forumUser.selectLimit(
	"SELECT a.* "
	+ " FROM " + forumPost.table + " a "
	+ " WHERE a.id > " + id + " "
	+ " AND a.status = 1 AND a.forum_id = " + fid + " AND a.course_user_id = " + cuid + " "
	+ " ORDER BY a.id ASC "
	, 1
);
DataSet next = forumUser.selectLimit(
	"SELECT a.* "
	+ " FROM " + forumPost.table + " a "
	+ " WHERE a.id < " + id + " "
	+ " AND a.status = 1 AND a.forum_id = " + fid + " AND a.course_user_id = " + cuid + " "
	+ " ORDER BY a.id DESC "
	, 1
);
if(prev.next()) {
	prev.put("subject_conv", m.cutString(prev.s("subject"), 80));
	prev.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", prev.s("reg_date")));
}
if(next.next()) {
	next.put("subject_conv", m.cutString(next.s("subject"), 80));
	next.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", next.s("reg_date")));
}

//출력
p.setLayout("pop");
p.setBody("management.forum_post_view");
p.setVar("p_title", "토론참여내역");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("forumuser", finfo);
p.setVar("info", info);
p.setVar("next", next);
p.setVar("prev", prev);

p.display();

%>