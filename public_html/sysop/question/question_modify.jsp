<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();
UserDao user = new UserDao();

//정보
DataSet info = question.query(
	"SELECT a.*, u.user_nm manager_name "
	+ " FROM " + question.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND a.manager_id IN (" + userId + ") " : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("category_nm", category.getTreeNames(info.i("category_id")));

//변수
boolean isSingle = "1".equals(info.s("question_type"));
boolean isMulti = "2".equals(info.s("question_type"));
boolean isShort = "3".equals(info.s("question_type"));
boolean isLong = "4".equals(info.s("question_type"));

boolean isChoice = isSingle || isMulti;
boolean isWrite = isShort || isLong;

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(m.ri("fid") == 0 && !"".equals(info.s("question_file"))) {
		question.item("question_file", "");
		if(!question.update("id = " + info.i("id") + "")) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFileRoot(m.getUploadPath(info.s("question_file")));

	} else if(m.ri("fid") > 0 && !"".equals(info.s("item" + m.ri("fid") + "_file"))) {
		question.item("item" + m.ri("fid") + "_file", "");
		if(!question.update("id = " + info.i("id") + "")) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFileRoot(m.getUploadPath(info.s("item" + m.ri("fid") + "_file")));

	}
	return;
}

//폼체크
f.addElement("category_id", info.i("category_id"), "hname:'카테고리', required:'Y'");
//f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리', required:'Y'");
f.addElement("grade", info.i("grade"), "hname:'난이도', required:'Y', option:'number'");
f.addElement("question_type", info.s("question_type"), "hname:'문제유형', required:'Y'");
f.addElement("question", info.s("question"), "hname:'문제', required:'Y'");
f.addElement("question_text", null, "hname:'문제설명', allowiframe:'Y', allowhtml:'Y'");
f.addElement("item_cnt", info.i("item_cnt"), "hname:'답변 갯수', option:'number'");
f.addElement("question_file", null, "hname:'문제파일', allow:'jpg|jpeg|gif|png'");
int cnt = m.ri("item_cnt", info.i("item_cnt"));
for(int i = 1; i <= cnt; i++) {
	f.addElement("item" + i, info.s("item" + i), "hname:'문항" + i + "'");
	f.addElement("item" + i + "_file", "", "hname:'문항파일" + i + "', allow:'jpg|jpeg|gif|png'");
}
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'사용여부', required:'Y'");


//등록
if(m.isPost() && f.validate()) {

	String questionText = f.get("question_text");
	//제한-이미지URI
	if(-1 < questionText.indexOf("<img") && -1 < questionText.indexOf("data:image/") && -1 < questionText.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = questionText.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}
	
	boolean isFormSingle = "1".equals(f.get("question_type"));
	boolean isFormMulti = "2".equals(f.get("question_type"));
	boolean isFormShort = "3".equals(f.get("question_type"));
	boolean isFormLong = "4".equals(f.get("question_type"));

	boolean isFormChoice = isFormSingle || isFormMulti;
	boolean isFormWrite = isFormShort || isFormLong;


	question.item("category_id", f.get("category_id"));
	question.item("grade", f.getInt("grade"));
	question.item("question_type", f.get("question_type"));
	question.item("question", f.get("question"));
	question.item("question_text", questionText);

	if(null != f.getFileName("question_file")) {
		File f1 = f.saveFile("question_file");
		if(null != f1) {
			question.item("question_file", f.getFileName("question_file"));
			if(!"".equals(info.s("question_file"))) m.delFileRoot(m.getUploadPath(info.s("question_file")));
		}
	}
	for(int i = 1; i <= 5; i++) {
		String field = "item" + i + "_file";
		if(isFormChoice && i <= f.getInt("item_cnt")) {
			if(null != f.getFileName(field)) {
				File itemfile = f.saveFile(field);
				if(null != itemfile) {
					question.item(field, f.getFileName(field));
					if(!"".equals(info.s(field))) m.delFileRoot(m.getUploadPath(info.s(field)));
				}
			}
			question.item("item" + i, f.get("item" + i));
		} else {
			question.item("item" + i, "");
			if(!"".equals(info.s(field))) m.delFileRoot(m.getUploadPath(info.s(field)));
			question.item("item" + i + "_file", "");
		}
	}

	question.item("item_cnt", isFormChoice ? f.getInt("item_cnt") : 1);
	question.item("answer", isFormMulti ? m.join("||", f.getArr("answer")) : (isFormLong ? f.get("answer2") : f.get("answer")));
	question.item("description", f.get("description"));
	if(!courseManagerBlock) question.item("manager_id", f.getInt("manager_id"));
	question.item("status", f.get("status"));

	if(!question.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("question_list.jsp?" + m.qs("id"), "parent");
	return;
}

//목록-항목
String today = m.time("yyyyMMdd");
DataSet list = new DataSet();
for(int i = 1; i <= 5; i++) {
	String field = "item" + i + "_file";
	list.addRow(); list.put("idx", i);
	list.put("file", info.s(field));
	list.put("file_conv", m.encode(info.s(field)));
	list.put("file_url",  (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s(field)));
	list.put("file_ek", m.encrypt(info.s(field) + today));
}

//포멧팅
info.put("set_value", "1".equals(info.s("question_type")) || "2".equals(info.s("question_type")));
info.put("question_file_conv", m.encode(info.s("question_file")));
info.put("question_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("question_file")));
info.put("question_file_ek", m.encrypt(info.s("question_file") + today));
info.put("question_text", m.htt(info.s("question_text")));


//서술형일 경우
if("4".equals(info.s("question_type"))) {
	info.put("answer2", info.s("answer"));
	info.put("answer", "");
}

//목록-카테고리
DataSet categories = category.getList(siteId);
while(categories.next()) {
	categories.put("display_block", categories.i("manager_id") == -99 || !courseManagerBlock || (courseManagerBlock && categories.i("manager_id") == userId));
}

//출력
p.setBody("question.question_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,idx"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar("temp_id", id);
p.setVar(info);
p.setLoop("list", list);

p.setLoop("types", m.arr2loop(question.types));
p.setLoop("grades", m.arr2loop(question.grades));
p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("categories", categories);

p.display();

%>