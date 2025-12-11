<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(40, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//제한
if(!isSend) { m.jsError("SMS 서비스를 신청하셔야 이용할 수 있습니다."); return; }

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();

//샘플다운로드
if("1".equals(m.rs("sample"))) {
	String filename = "sample.xls";
	File f1 = new File(docRoot + "/sysop/sms/sample.xls");

	if(!f1.exists()) {
		m.jsAlert("샘플파일이 없습니다. 관리자에게 문의하세요.");
		return;
	}
	m.download(docRoot + "/sysop/sms/sample.xls", filename);
	return;
}

//정보-회원
DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
if(!uinfo.next()) { m.jsError("해당 회원 정보가 없습니다."); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "";

//폼입력
int id = m.ri("id");

//정보
DataSet info = new DataSet();
if(id == 0) {
	info.addRow();
	info.put("id", 0);
	info.put("sender", mobile);
	info.put("subject", "");
	info.put("modify", false);
	info.put("t_link", "insert");
} else {
	info = sms.find("status = 1 AND id = " + id + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
	info.put("t_link", "modify");
	info.put("modify", true);
}

//폼체크
f.addElement("sender", siteinfo.s("sms_sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", info.s("content"), "hname:'내용', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");
f.addElement("att_file", null, "hname:'엑셀파일', required:'Y', allow:'xls|xlsx'");

//등록
if(m.isPost() && f.validate()) {

	String[] cols = { "col0=>name", "col1=>mobile" };
	DataSet fields = m.arr2loop(cols);

	File attFile = f.saveFile("att_file");
	if(attFile == null) {
		m.jsAlert("파일 업로드하는데 실패했습니다.");
		return;
	}

	ExcelReader ex = new ExcelReader(attFile.getPath());
	DataSet users = ex.getDataSet();
	users.next(); //첫번째 타이틀은 건너뛴다.
	ex.close();
	attFile.delete();
	if(users.size() < 2) { m.jsAlert("대상회원이 없습니다."); return; }


	//변수
	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;
	int newId = sms.getSequence();

	sms.item("id", newId);
	sms.item("site_id", siteId);

	sms.item("module", "excel");
	sms.item("module_id", 0);
	sms.item("user_id", userId);
	sms.item("sms_type", "I");
	sms.item("sender", f.get("sender"));
	sms.item("content", f.get("content"));
	sms.item("resend_id", 0);
	sms.item("send_cnt", 0);
	sms.item("fail_cnt", 0);
	sms.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	sms.item("reg_date", m.time("yyyyMMddHHmmss"));
	sms.item("status", 1);

	if(!sms.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//SMS 발송
	int sendCnt = 0;
	int failCnt = 0;
	String mobileEncrypt = "";
	while(users.next()) {
		mobile = users.s("col1");
		mobileEncrypt = !"".equals(mobile) ? SimpleAES.encrypt(mobile) : "";
		smsUser.item("site_id", siteId);
		smsUser.item("sms_id", newId);
		smsUser.item("mobile", mobileEncrypt);
		smsUser.item("user_id", -99);
		smsUser.item("user_nm", users.s("col0"));
		if(sms.isMobile(mobile)) {
			smsUser.item("send_yn", "Y");
			if(smsUser.insert()) {
				if(isSend) sms.send(mobile, f.get("sender"), f.get("content"), sendDate);
				sendCnt++;
			}
		} else {
			smsUser.item("send_yn", "N");
			if(smsUser.insert()) { failCnt++; }
		}
	}

	//발송건수
	sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId);

	m.jsReplace("sms_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("sms.sms_excel");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.display();

%>