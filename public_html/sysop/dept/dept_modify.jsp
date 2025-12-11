<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(43, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
FileDao file = new FileDao();

//정보
DataSet info = userDept.query(
	" SELECT a.*, f.filename b2b_file "
	+ " FROM " + userDept.table + " a " 
	+ " LEFT JOIN " + file.table + " f ON f.module = 'dept' AND f.module_id = a.id AND f.status = 1 "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//변수
boolean changed = m.isPost() && !"".equals(f.get("parent_id")) && !info.s("parent_id").equals(f.get("parent_id"));
int pid = changed ? f.getInt("parent_id") : info.i("parent_id");

//정보-상위
DataSet pinfo = userDept.find("id = " + pid + " AND status != -1 AND site_id = " + siteId + "");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	userDept.findCount("site_id = " + siteId + " AND status != -1 AND parent_id = " +  pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: userDept.findCount("site_id = " + siteId + " AND status != -1 AND depth = 1");


//순서
DataSet sortList = new DataSet();
for(int i = 0; i < maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}


//폼체크
f.addElement("dept_nm", info.s("dept_nm"), "hname:'소속명', required:'Y'");
f.addElement("dept_desc", null, "hname:'소속설명'");
f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");
f.addElement("dept_cd", info.s("dept_cd"), "hname:'소속코드'");
f.addElement("auth2_yn", info.s("auth2_yn"), "hname:'2차인증설정'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y', option:'number'");
f.addElement("b2b_nm", info.s("b2b_nm"), "hname:'단체명'");
f.addElement("b2b_file", null, "hname:'단체로고', allow:'jpg|gif|png|jpeg'");
f.addElement("b2b_domain", info.s("b2b_domain"), "hname:'접속URL'");

//삭제-첨부파일
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("b2b_file"))) {
		file.item("status", "-1");
		if(!file.update("module = 'dept' AND module_id = " + id)) {}
		m.delFileRoot(m.getUploadPath(info.s("b2b_file")));
	}
	return;
}

//등록
if(m.isPost() && f.validate()) {

	userDept.item("dept_nm", f.get("dept_nm"));
	userDept.item("dept_desc", f.get("dept_desc"));
	userDept.item("sort", f.getInt("sort"));
	userDept.item("dept_cd", f.get("dept_cd"));
	if(!changed) userDept.item("depth", pinfo.i("depth") + 1);
	userDept.item("b2b_domain", f.get("b2b_domain"));
	userDept.item("b2b_nm", f.get("b2b_nm"));
	userDept.item("auth2_yn", f.get("auth2_yn"));
	userDept.item("display_yn", f.get("display_yn", "N"));
	userDept.item("status", f.getInt("status"));

	if(!userDept.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	if(changed) { // 부모가 변경 되었을 경우
		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			userDept.execute("UPDATE " + userDept.table + " SET depth = depth + (" + cdepth + ") WHERE id IN (" + userDept.getSubIdx(siteId, id) + ")");
		}

		// 이동된 위치를 다시 정렬한다.
		userDept.sort(id, f.getInt("sort"), maxSort + 1);
		// 이동전 위치를 정렬한다.
		userDept.autoSort(info.i("depth"), info.i("parent_id"), siteId);
	} else {
		// 해당 위치만 정렬한다.
		userDept.sort(id, f.getInt("sort"), info.i("sort"));
	}

	//파일-B2B로고
	if(null != f.getFileName("b2b_file")) {
		File f1 = f.saveFile("b2b_file");
		if(null != f1) {

			file.item("status", "-1");
			if(!file.update("module = 'dept' AND module_id = " + id)) {}

			file.item("module", "dept");
			file.item("module_id", id);
			file.item("site_id", siteId);
			file.item("file_nm", f.getFileName("b2b_file"));
			file.item("filename", f.getFileName("b2b_file"));
			file.item("filetype", f.getFileType("b2b_file"));
			file.item("filesize", f1.length());
			file.item("realname", f1.getName());
			file.item("main_yn", "N");
			file.item("reg_date", m.time("yyyyMMddHHmmss"));
			file.item("status", 1);
			file.insert();

			//파일리사이징
			/*
			try {
				if(f.getFileName("b2b_file").matches("(?i)^.+\\.(jpg|png|gif|bmp)$")) {
					String imgPath = m.getUploadPath(f.getFileName("b2b_file"));
					String cmd = "convert -resize 700x " + imgPath + " " + imgPath;
					Runtime.getRuntime().exec(cmd);
				}
			} catch(Exception e) { }
			*/

		}
	}

	m.js("parent.left.location.href='dept_tree.jsp?" + m.qs() + "&sid=" + id + "';");
	m.jsReplace("dept_modify.jsp?" + m.qs());
	return;

}

//상위코드 명
DataSet departments = userDept.getList(siteId);
String pnames = userDept.getTreeNames(id);
info.put("parent_name", "".equals(pnames) ? "-" : pnames);

if(!"".equals(info.s("b2b_file"))) {
	info.put("b2b_file_path", m.getUploadPath(info.s("b2b_file")));
	info.put("b2b_file_conv", m.encode(info.s("b2b_file")));
	info.put("b2b_file_url", m.getUploadUrl(info.s("b2b_file")));
	info.put("b2b_file_ek", m.encrypt(info.s("b2b_file") + m.time("yyyyMMdd")));
}

//출력
p.setLayout("blank");
p.setBody("dept.dept_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("pinfo", pinfo);
p.setLoop("admins", user.find("site_id = " + siteId + " AND dept_id IN ('" + m.join("', '", userDept.getParentNodes(id + "")) + "') AND user_kind = 'D' AND status = 1"));
p.setLoop("sort_list", sortList);
p.setLoop("auth2_yn", m.arr2loop(userDept.auth2Yn));
p.setLoop("display_yn", m.arr2loop(userDept.displayYn));
p.setLoop("status_list", m.arr2loop(userDept.statusList));
p.setVar("top", pid == 0);
p.setVar("join_b2b_yn", "Y".equals(SiteConfig.s("join_b2b_yn")));
p.setVar("join_b2b_domain", SiteConfig.s("join_b2b_domain"));
p.display();

%>