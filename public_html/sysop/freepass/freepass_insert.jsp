<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(130, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
FreepassDao freepass = new FreepassDao(siteId);

//폼체크
f.addElement("freepass_nm", null, "hname:'프리패스명', required:'Y'");
f.addElement("freepass_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("request_sdate", null, "hname:'신청시작일', required:'Y'");
f.addElement("request_edate", null, "hname:'신청종료일', required:'Y'");
f.addElement("freepass_day", 0, "hname:'사용기간', required:'Y', option:'number', min:'1'");
f.addElement("limit_cnt", 0, "hname:'사용횟수', required:'Y', option:'number'");
f.addElement("list_price", 0, "hname:'정가', required:'Y', option:'number'");
f.addElement("price", 0, "hname:'판매가', required:'Y', option:'number'");
f.addElement("disc_group_yn", "Y", "hname:'그룹할인적용여부'");
f.addElement("subtitle", null, "hname:'소개문구'");
f.addElement("content", null, "hname:'설명', allowhtml:'Y'");
f.addElement("sale_yn", "N", "hname:'판매여부', required:'Y'");
f.addElement("display_yn", "N", "hname:'노출여부', required:'Y'");
f.addElement("status", 0, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	//제한-용량
	String subtitle = f.get("subtitle");
	int bytest = subtitle.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(500 < bytest) { m.jsAlert("과정목록 소개문구 내용은 500바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytest + "바이트)"); return; }

	//등록
	int newId = freepass.getSequence();
	freepass.item("id", newId);
	freepass.item("site_id", siteId);
	freepass.item("freepass_nm", f.get("freepass_nm"));
	freepass.item("request_sdate", m.time("yyyyMMdd", f.get("request_sdate")));
	freepass.item("request_edate", m.time("yyyyMMdd", f.get("request_edate")));
	freepass.item("freepass_day", f.getInt("freepass_day"));
	freepass.item("categories", "||");
	freepass.item("subtitle", subtitle);
	freepass.item("content", f.get("content"));
	freepass.item("list_price", f.getInt("list_price"));
	freepass.item("price", f.getInt("price"));
	freepass.item("disc_group_yn", f.get("disc_group_yn", "Y"));
	freepass.item("limit_cnt", f.getInt("limit_cnt"));
	freepass.item("sale_yn", f.get("sale_yn"));
	freepass.item("display_yn", f.get("display_yn"));
	freepass.item("reg_date", m.time("yyyyMMddHHmmss"));
	freepass.item("status", f.getInt("status"));

	//파일
	if(null != f.getFileName("freepass_file")) {
		File f1 = f.saveFile("freepass_file");
		if(f1 != null) {
			freepass.item("freepass_file", f.getFileName("freepass_file"));
			try {
				String imgPath = m.getUploadPath(f.getFileName("freepass_file"));
				String cmd = "convert -resize 500x " + imgPath + " " + imgPath;
				Runtime.getRuntime().exec(cmd);
			}
			catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
			catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
		}
	}

	if(!freepass.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("freepass_modify.jsp?id=" + newId + "&" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("freepass.freepass_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("sale_yn", m.arr2loop(freepass.saleYn));
p.setLoop("display_yn", m.arr2loop(freepass.displayYn));
p.setLoop("status_list", m.arr2loop(freepass.statusList));

p.display();

%>
