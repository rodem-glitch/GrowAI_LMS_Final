<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int fid = m.ri("fid");
int cuid = m.ri("cuid");
if(fid == 0 || cuid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ForumUserDao forumUser = new ForumUserDao();
ForumPostDao forumPost = new ForumPostDao();
UserDao user = new UserDao(isBlindUser);

//정보
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
if(!finfo.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }
finfo.put("confirm_str", "Y".equals(finfo.s("confirm_yn")) ? "평가완료" : "미평가");
user.maskInfo(finfo);

//기록-개인정보조회
if(finfo.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, finfo.size(), "이러닝 운영", finfo);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(forumPost.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.forum_id = " + fid + "");
lm.addWhere("a.course_user_id = " + cuid + "");
lm.setOrderBy("a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), 85));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
}

//출력
p.setLayout("pop");
p.setBody("management.forum_post");
p.setVar("p_title", "토론참여내역");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("finfo", finfo);
p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>