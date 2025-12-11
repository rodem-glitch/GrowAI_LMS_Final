<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(82, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteDao site = new SiteDao();
UserDeptDao userDept = new UserDeptDao();
UserDao user = new UserDao();
ApiLogDao apiLog = new ApiLogDao();

//정보
DataSet info = site.query(
	" SELECT a.* "
	+ " , (SELECT COUNT(*) FROM " + apiLog.table + " WHERE site_id = a.id "
		+ " AND reg_date >= '" + m.time("yyyyMM01000000") + "' AND reg_date <= '" + m.time("yyyyMMddHHmmss") + "' AND return_code = '000') api_cnt "
	+ " FROM " + site.table + " a "
	+ " WHERE a.id = '" + siteId + "' "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//API,SSO토큰
if("api".equals(m.rs("mode"))) {
	String token = m.getUniqId(32);
	site.item("api_token", token);
	if(!site.update("id = " + siteId)) { out.print("오류가 발생했습니다."); return; }
	out.print(token);
	return;
} else if("apidel".equals(m.rs("mode"))) {
	site.item("api_token", "");
	if(0 > site.execute("UPDATE " + site.table + " SET api_token = NULL WHERE id = " + siteId)) { out.print("오류가 발생했습니다."); return; }
	out.print("");
	return;
}

//파일삭제
if("fdel".equals(m.request("mode"))) {
	if("logo".equals(m.rs("type"))) {
		if(!"".equals(info.s("logo"))) {
			site.item("logo", "");
			if(!site.update("id = " + siteId + "")) { m.jsAlert("로고를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("logo")));
		}

	} else if("certificate".equals(m.rs("type"))) {
		if(!"".equals(info.s("certificate_file"))) {
			site.item("certificate_file", "");
			if(!site.update("id = " + siteId + "")) { m.jsAlert("수료증 이미지를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("certificate_file")));
		}
	} else if("course".equals(m.rs("type"))) {
		if(!"".equals(info.s("course_file"))) {
			site.item("course_file", "");
			if(!site.update("id = " + siteId + "")) { m.jsAlert("수강증 이미지를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("course_file")));
		}
	}
	return;
}

//폼체크
f.addElement("site_nm", info.s("site_nm"), "hname:'이름', required:'Y'");
f.addElement("logo", null, "hname:'로고이미지'");
f.addElement("company_nm", info.s("company_nm"), "hname:'회사명', required:'Y'");
f.addElement("ceo_nm", info.s("ceo_nm"), "hname:'대표명'");
f.addElement("biz_type", info.s("biz_type"), "hname:'사업자번호 타입'");
f.addElement("biz_no", info.s("biz_no"), "hname:'사업자번호'");
f.addElement("zipcode", info.s("zipcode"), "hname:'우편번호'");
f.addElement("new_addr", info.s("new_addr"), "hname:'주소'");
f.addElement("addr_dtl", info.s("addr_dtl"), "hname:'상세주소'");
f.addElement("copyright", null, "hname:'하단HTML'");
f.addElement("allow_ip", info.s("allow_ip"), "hname:'관리자 접근허용IP'");

f.addElement("site_email", info.s("site_email"), "hname:'발신자이메일', option:'email'");
f.addElement("receive_email", info.s("receive_email"), "hname:'수신이메일', option:'email'");
f.addElement("receive_phone", info.s("receive_phone"), "hname:'수신전화번호'");
f.addElement("alert_email", info.s("alert_email"), "hname:'알림메일수신주소', option:'email'");
f.addElement("alert_phone", info.s("alert_phone"), "hname:'알림SMS수신전화번호'");
f.addElement("alert_type_email", null, "hname:'알림메일수신타입'");
f.addElement("alert_type_sms", null, "hname:'알림SMS수신타입'");

f.addElement("api_token", info.s("api_token"), "hname:'API 엑세스 토큰'");
f.addElement("api_ip_addr", info.s("api_ip_addr"), "hname:'API 허용 IP'");

f.addElement("certificate_file", null, "hname:'수료증이미지', allow:'jpg|jpeg|png|gif'");
f.addElement("course_file", null, "hname:'수강증이미지', allow:'jpg|jpeg|png|gif'");


//수정
if(m.isPost() && f.validate()) {

	site.item("site_nm", f.get("site_nm"));
	if(f.getFileName("logo") != null) {
		File f1 = f.saveFile("logo");
		if(f1 != null) {
			site.item("logo", f.getFileName("logo"));
			if(!"".equals(info.s("logo"))) m.delFileRoot(m.getUploadPath(info.s("logo")));
		}
	}

	site.item("company_nm", f.get("company_nm"));
	site.item("ceo_nm", f.get("ceo_nm"));
	site.item("biz_type", f.get("biz_type"));
	site.item("biz_no", f.get("biz_no"));
	site.item("zipcode", f.get("zipcode"));
	site.item("new_addr", f.get("new_addr"));
	site.item("addr_dtl", f.get("addr_dtl"));
	site.item("copyright", f.get("copyright"));
	site.item("allow_ip", f.get("allow_ip"));

	site.item("site_email", f.get("site_email"));
	site.item("receive_email", f.get("receive_email"));
	site.item("receive_phone", f.get("receive_phone"));
	site.item("alert_email", f.get("alert_email"));
	site.item("alert_phone", f.get("alert_phone"));
	site.item("alert_type_email", "|" + m.join("|", f.getArr("alert_type_email")) + "|");
	site.item("alert_type_sms", "|" + m.join("|", f.getArr("alert_type_sms")) + "|");

	site.item("api_ip_addr", f.get("api_ip_addr"));

	if(null != f.getFileName("certificate_file")) {
		File f1 = f.saveFile("certificate_file");
		if(f1 != null) {
			site.item("certificate_file", f.getFileName("certificate_file"));
			m.delFileRoot(m.getUploadPath(info.s("certicficate_file")));
		}
	}
	if(null != f.getFileName("course_file")) {
		File f1 = f.saveFile("course_file");
		if(f1 != null) {
			site.item("course_file", f.getFileName("course_file"));
			m.delFileRoot(m.getUploadPath(info.s("course_file")));
		}
	}

	if(!site.update("id = " + siteId + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; 	}

	//캐쉬 삭제
	site.remove(info.s("domain"));
	if(!"".equals(info.s("domain2"))) site.remove(info.s("domain2"));

	m.jsAlert("수정되었습니다.");
	m.jsReplace("site_info_modify.jsp", "parent");
	return;
}

//포멧팅
info.put("logo_conv", m.encode(info.s("logo")));
info.put("logo_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("logo")));
info.put("logo_ek", m.encrypt(info.s("logo") + m.time("yyyyMMdd")));

info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("start_date")));
info.put("end_date_conv", m.time("yyyy.MM.dd", info.s("end_date")));
info.put("user_max_conv", m.nf(info.i("user_max")));

info.put("certificate_file_conv", m.encode(info.s("certificate_file")));
info.put("certificate_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("certificate_file")));
info.put("certificate_file_ek", m.encrypt(info.s("certificate_file") + m.time("yyyyMMdd")));

info.put("course_file_conv", m.encode(info.s("course_file")));
info.put("course_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("course_file")));
info.put("course_file_ek", m.encrypt(info.s("course_file") + m.time("yyyyMMdd")));

//출력
p.setBody("site.site_info_modify");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("tab_info", "current");
p.setLoop("alert_types", m.arr2loop(Site.alertTypes));
p.display();

%>