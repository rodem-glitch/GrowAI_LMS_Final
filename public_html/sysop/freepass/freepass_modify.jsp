<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(130, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
FreepassDao freepass = new FreepassDao(siteId);
FreepassCourseDao freepassCourse = new FreepassCourseDao(siteId);
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");

//정보
DataSet info = freepass.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("freepass_file"))) {
		freepass.item("freepass_file", "");
		if(freepass.update("id = " + id)) {
			m.delFileRoot(m.getUploadPath(info.s("freepass_file")));
		}
	}
	return;
}

//폼체크
f.addElement("freepass_nm", info.s("freepass_nm"), "hname:'프리패스명', required:'Y'");
f.addElement("request_sdate", m.time("yyyy-MM-dd", info.s("request_sdate")), "hname:'신청시작일', required:'Y'");
f.addElement("request_edate", m.time("yyyy-MM-dd", info.s("request_edate")), "hname:'신청종료일', required:'Y'");
f.addElement("freepass_day", info.i("freepass_day"), "hname:'사용기간', required:'Y', option:'number', min:'1'");
f.addElement("freepass_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("limit_cnt", info.i("limit_cnt"), "hname:'사용횟수', required:'Y', option:'number'");
f.addElement("list_price", info.i("list_price"), "hname:'정가', required:'Y', option:'number'");
f.addElement("price", info.i("price"), "hname:'판매가', required:'Y', option:'number'");
f.addElement("disc_group_yn", info.s("disc_group_yn"), "hname:'그룹할인적용여부'");
f.addElement("subtitle", null, "hname:'소개문구'");
f.addElement("content", null, "hname:'설명'");
f.addElement("sale_yn", info.s("sale_yn"), "hname:'판매여부', required:'Y'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y', option:'number'");

//수정
if(m.isPost() && f.validate()) {

	//제한-용량
	String subtitle = f.get("subtitle");
	int bytest = subtitle.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(500 < bytest) { m.jsAlert("과정목록 소개문구 내용은 500바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytest + "바이트)"); return; }

	//수정
	freepass.item("freepass_nm", f.get("freepass_nm"));
	freepass.item("request_sdate", m.time("yyyyMMdd", f.get("request_sdate")));
	freepass.item("request_edate", m.time("yyyyMMdd", f.get("request_edate")));
	freepass.item("freepass_day", f.getInt("freepass_day"));
	freepass.item("subtitle", subtitle);
	freepass.item("content", f.get("content"));
	freepass.item("list_price", f.getInt("list_price"));
	freepass.item("price", f.getInt("price"));
	freepass.item("disc_group_yn", f.get("disc_group_yn"));
	freepass.item("limit_cnt", f.getInt("limit_cnt"));
	freepass.item("sale_yn", f.get("sale_yn"));
	freepass.item("display_yn", f.get("display_yn"));
	freepass.item("status", f.getInt("status"));

	//파일
	if(null != f.getFileName("freepass_file")) {
		File f1 = f.saveFile("freepass_file");
		if(f1 != null) {
			freepass.item("freepass_file", f.getFileName("freepass_file"));
			if(!"".equals(info.s("freepass_file")) && new File(m.getUploadPath(info.s("freepass_file"))).exists()) {
				m.delFileRoot(m.getUploadPath(info.s("freepass_file")));
			}
			try {
				String imgPath = m.getUploadPath(f.getFileName("freepass_file"));
				String cmd = "convert -resize 500x " + imgPath + " " + imgPath;
				Runtime.getRuntime().exec(cmd);
			}
			catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
			catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
		}
	}
	if(!freepass.update("id = " + id)) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("freepass_modify.jsp?" + m.qs(""), "parent");
	return;
}

//목록
String categories = !"".equals(info.s("categories")) ? m.replace(info.s("categories").substring(1, info.s("categories").length()-1), "|", ",") : "";
DataSet list = course.query(
	" SELECT a.*, ct.category_nm "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + category.table + " ct ON a.category_id = ct.id "
	+ " WHERE "
	+ (!"".equals(categories) ? " a.status = 1 AND ( a.category_id IN (" + categories + ") OR " : " ( a.status = 1 AND ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + freepassCourse.table + " "
		+ " WHERE freepass_id = " + id + " AND add_type = 'A' "
		+ " AND course_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + freepassCourse.table + " "
		+ " WHERE freepass_id = " + id + " AND add_type = 'D' "
		+ " AND course_id = a.id "
	+ " ) "
);
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "프리패스관리-" + info.s("freepass_nm") + "(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>과정아이디", "course_nm=>과정명", "category_nm=>카테고리", "lesson_day=>수강일수", "lesson_time=>수강시간(시)", "price=>가격", "credit=>학점", "assign_progress=>출석(진도) 배점", "assign_exam=>평가 배점", "assign_homework=>과제 배점", "assign_forum=>토론 배점", "assign_etc=>기타 배점", "limit_progress=>출석(진도) 수료기준", "limit_exam=>평가 수료기준", "limit_homework=>과제 수료기준", "limit_forum=>토론 수료기준", "limit_etc=>기타 수료기준", "limit_total_score=>총점 수료기준", "limit_people_yn=>수강인원제한 사용유무", "limit_people=>수강제한인원", "limit_lesson_yn=>학습차시제한 사용유무", "limit_lesson=>학습제한 강의 수", "lesson_order_yn=>진도 순차적용 여부", "class_member=>반별인원", "period_yn=>차시별 학습기간 사용여부", "restudy_yn=>복습허용유무", "restudy_day=>복습허용기간", "complete_auto_yn=>자동수료완료여부", "course_file=>메인이미지", "content1_title=>텍스트1 타이틀", "content1=>텍스트1 내용", "content2_title=>텍스트2 타이틀", "content2=>텍스트2 내용", "reg_date_conv=>등록일", "status_conv=>상태" }, "프리패스관리-" + info.s("freepass_nm") + "(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//포맷팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("course_cnt", m.nf(list.size()));
info.put("freepass_file_conv", m.encode(info.s("freepass_file")));
info.put("freepass_file_url", m.getUploadUrl(info.s("freepass_file")));
info.put("freepass_file_ek", m.encrypt(info.s("freepass_file") + m.time("yyyyMMdd")));

//목록
DataSet clist = category.getList(siteId);
DataSet inlist = freepassCourse.query(
	"SELECT c.id, c.onoff_type, c.course_nm, c.category_id, ct.category_nm FROM " + freepassCourse.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id "
	+ " WHERE a.add_type = 'A' AND a.freepass_id = " + id + " "
);
while(inlist.next()) {
	inlist.put("onoff_type_conv", m.getItem(inlist.s("onoff_type"), course.onoffPackageTypes));
	inlist.put("course_nm_conv", m.cutString(inlist.s("course_nm"), 80));
	inlist.put("cate_name", category.getTreeNames(inlist.i("category_id")));
}
DataSet exlist = freepassCourse.query(
	"SELECT c.*, ct.category_nm FROM " + freepassCourse.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id "
	+ " WHERE a.add_type = 'D' AND a.freepass_id = " + id + " "
);
while(exlist.next()) {
	exlist.put("onoff_type_conv", m.getItem(exlist.s("onoff_type"), course.onoffPackageTypes));
	exlist.put("course_nm_conv", m.cutString(exlist.s("course_nm"), 80));
	exlist.put("cate_name", category.getTreeNames(exlist.i("category_id")));
}

//목록
//DataSet clist = category.find("status = 1 AND module = 'course' AND site_id = " + siteId + "", "*", "parent_id ASC, sort ASC");

//출력
p.setBody("freepass.freepass_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("modify", true);
p.setVar("tab_modify", "current");

p.setLoop("category_list", clist);
p.setLoop("inlist", inlist);
p.setLoop("exlist", exlist);
p.setVar("category_cnt", clist.size());
p.setVar("inlist_cnt", inlist.size());
p.setVar("exlist_cnt", exlist.size());

p.setLoop("sale_yn", m.arr2loop(freepass.saleYn));
p.setLoop("display_yn", m.arr2loop(freepass.displayYn));
p.setLoop("status_list", m.arr2loop(freepass.statusList));

p.setVar("fid", id);
p.display();

%>