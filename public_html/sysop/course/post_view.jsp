<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String code = m.rs("code", "notice");
String mode = m.rs("mode");
int id = m.ri("id");
int bid = m.ri("bid");
if("".equals(code) || id == 0 || bid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClPostDao post = new ClPostDao();
ClBoardDao board = new ClBoardDao();
ClFileDao file = new ClFileDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
KollusFileDao kollusFile = new KollusFileDao();

//변수
boolean managementBlock = "management".equals(m.rs("mode"));

//정보-게시판
DataSet binfo = board.find("id = " + bid + " AND status = 1");
if(!binfo.next()) { m.jsError("해당 게시판 정보가 없습니다."); return; }
String btype = binfo.s("board_type");
p.setVar(btype + "_type_block", true);

//정보
DataSet info = post.query(
	"SELECT a.*, b.board_nm, b.board_type, b.code, c.course_nm, u.login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND b.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.status != -1 AND a.id = " + id + " "
	+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("user_id", info.i("user_id") > 0 ? info.s("user_id") : "");
info.put("login_id_conv", "".equals(info.s("login_id")) ? "-" : info.s("login_id"));
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.getInt("hit_cnt")));
info.put("content_conv", m.nl2br(info.s("content") + "<br/>" + kollusFile.getVideo(info.s("upload_file_key"))));
info.put("display_yn_conv", m.getItem(info.s("display_yn"), post.displayYn));
user.maskInfo(info);

//기록-개인정보조회
if(info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);


//목록-파일
DataSet files = file.find("module = 'post' AND module_id = " + id + "");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}


//이전다음글
String sf = m.request("s_field");
String sk = m.request("s_keyword");
if(!"".equals(sf)) post.addSearch(sf, sk, "LIKE");
else if("".equals(sf) && !"".equals(sk)) {
	Vector<String> v = new Vector<String>();
	v.add("u.login_id LIKE '%" + sk + "%'");
	v.add("a.writer LIKE '%" + sk + "%'");
	v.add("a.subject LIKE '%" + sk + "%'");
	v.add("a.content LIKE '%" + sk + "%'");
	post.addWhere("(" + m.join(" OR ", v.toArray()) + ")");
}
DataSet prev = post.getPrevPost(info.i("board_id"), info.i("thread"), info.s("depth"));
DataSet next = post.getNextPost(info.i("board_id"), info.i("thread"), info.s("depth"));
if(prev.next()) { prev.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", prev.s("reg_date"))); }
if(next.next()) { next.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", next.s("reg_date"))); }


//출력
p.setBody("course.post_view");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("prev", prev);
p.setVar("next", next);
p.setLoop("files", files);

p.setVar("board", binfo);
p.setVar("management_block", managementBlock);
p.setLoop("proc_status_list", m.arr2loop(post.procStatusList));
p.display();

%>