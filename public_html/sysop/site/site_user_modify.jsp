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
	" SELECT a.*, b.user_nm super_name "
	+ " , (SELECT COUNT(*) FROM " + apiLog.table + " WHERE site_id = a.id "
		+ " AND reg_date >= '" + m.time("yyyyMM01000000") + "' AND reg_date <= '" + m.time("yyyyMMddHHmmss") + "' AND return_code = '000') api_cnt "
	+ " FROM " + site.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.super_id = b.id AND a.id = b.site_id AND b.user_kind = 'S' "
	+ " WHERE a.id = '" + siteId + "' "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

DataSet cinfo = SiteConfig.getDataSet(siteId);

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
//f.addElement("memo", info.s("memo"), "hname:'설명'");

f.addElement("mng_nm", info.s("mng_nm"), "hname:'담당자명'");
f.addElement("mng_mobile", info.s("mng_mobile"), "hname:'담당자연락처'");
f.addElement("mng_email", info.s("mng_email"), "hname:'담당자이메일'");
f.addElement("mng_fax", info.s("mng_fax"), "hname:'담당자FAX'");

f.addElement("start_date", m.time("yyyy-MM-dd", info.s("start_date")), "hname:'시작일'");
f.addElement("end_date", m.time("yyyy-MM-dd", info.s("end_date")), "hname:'종료일'");
f.addElement("ftp_id", info.s("ftp_id"), "hname:'FTP계정'");
f.addElement("sso_yn", info.s("sso_yn"), "hname:'SSO 사용여부'");
f.addElement("sso_key", info.s("sso_key"), "hname:'SSO 키'");
f.addElement("sso_url", info.s("sso_url"), "hname:'SSO URL'");

f.addElement("sms_yn", info.s("sms_yn"), "hname:'SMS 사용여부'");
f.addElement("sms_id", info.s("sms_id"), "hname:'SMS 아이디'");
f.addElement("sms_pw", info.s("sms_pw"), "hname:'SMS 비밀번호'");
f.addElement("sms_sender", info.s("sms_sender"), "hname:'SMS 발신번호'");

f.addElement("pg_nm", info.s("pg_nm"), "hname:'결제사'");
f.addElement("pg_id", info.s("pg_id"), "hname:'상점아이디'");
f.addElement("pg_key", info.s("pg_key"), "hname:'상점키'");
f.addElement("pg_escrow_yn", info.s("pg_escrow_yn"), "hname:'에스크로 사용여부'");

f.addElement("api_token", info.s("api_token"), "hname:'API 엑세스 토큰'");
f.addElement("api_ip_addr", info.s("api_ip_addr"), "hname:'API 허용 IP'");

f.addElement("video_key", info.s("video_key"), "hname:'위캔디오API키'");
f.addElement("video_pkg", info.s("video_pkg"), "hname:'위캔디오패키지아이디'");
f.addElement("super_nm", info.s("super_name"), "hname:'슈퍼관리자아이디', required:'Y'");
f.addElement("join_status", info.i("join_status"), "hname:'회원가입 상태', required:'Y'");
f.addElement("dept_id", info.i("dept_id"), "hname:'기본 회원소속', required:'Y'");
f.addElement("site_email", info.s("site_email"), "hname:'발신자이메일', option:'email'");
f.addElement("receive_email", info.s("receive_email"), "hname:'수신이메일', option:'email'");
f.addElement("receive_phone", info.s("receive_phone"), "hname:'수신전화번호'");
f.addElement("certificate_file", null, "hname:'수료증이미지', allow:'jpg|jpeg|png|gif'");
f.addElement("pay_notice", null, "hname:'결제페이지안내문구', allowhtml:'Y'");
f.addElement("pay_notice_yn", info.s("pay_notice_yn"), "hname:'결제페이지안내문구 노출여부'");
f.addElement("copyright", null, "hname:'하단HTML'");
f.addElement("needs", info.s("needs"), "hname:'회원허용필드'");
f.addElement("delivery_free_price", cinfo.i("delivery_free_price"), null);


//수정
if(m.isPost() && f.validate()) {

	site.item("site_nm", f.get("site_nm"));
	site.item("copyright", f.get("copyright"));
	if(f.getFileName("logo") != null) {
		File f1 = f.saveFile("logo");
		if(f1 != null) {
			site.item("logo", f.getFileName("logo"));
			if(!"".equals(info.s("logo"))) m.delFileRoot(m.getUploadPath(info.s("logo")));
		}
	}
	site.item("needs", f.get("needs"));
	site.item("sms_sender", f.get("sms_sender"));

	//site.item("memo", f.get("memo"));
	site.item("company_nm", f.get("company_nm"));
	site.item("ceo_nm", f.get("ceo_nm"));
	site.item("super_id", f.getInt("super_id"));
	site.item("join_status", f.getInt("join_status"));
	site.item("zipcode", f.get("zipcode"));
	site.item("new_addr", f.get("new_addr"));
	site.item("addr_dtl", f.get("addr_dtl"));
	site.item("biz_type", f.get("biz_type"));
	site.item("biz_no", f.get("biz_no"));

	site.item("pg_escrow_yn", f.get("pg_escrow_yn"));
	site.item("pay_notice", f.get("pay_notice"));
	site.item("pay_notice_yn", f.get("pay_notice_yn"));

	site.item("site_email", f.get("site_email"));
	site.item("receive_email", f.get("receive_email"));
	site.item("receive_phone", f.get("receive_phone"));

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
	site.item("dept_id", f.getInt("dept_id"));

	if(!site.update("id = " + siteId + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; 	}

	SiteConfig.put("delivery_free_price", f.getInt("delivery_free_price"));

	//캐쉬 삭제
	site.remove(info.s("domain"));
	if(!"".equals(info.s("domain2"))) site.remove(info.s("domain2"));

	m.jsAlert("수정되었습니다.");
	m.jsReplace("site_info.jsp", "parent");
	return;
}

//포멧팅
info.put("logo_conv", m.encode(info.s("logo")));
info.put("logo_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("logo")));
info.put("logo_ek", m.encrypt(info.s("logo") + m.time("yyyyMMdd")));

info.put("certificate_file_conv", m.encode(info.s("certificate_file")));
info.put("certificate_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("certificate_file")));
info.put("certificate_file_ek", m.encrypt(info.s("certificate_file") + m.time("yyyyMMdd")));

info.put("course_file_conv", m.encode(info.s("course_file")));
info.put("course_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("course_file")));
info.put("course_file_ek", m.encrypt(info.s("course_file") + m.time("yyyyMMdd")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

info.put("ovp_vendor_conv", m.getItem(info.s("ovp_vendor"), site.ovpVendors));
info.put("catenoid_block", "C".equals(info.s("ovp_vendor")));

//출력
p.setBody("site.site_user_modify");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("status_list", m.arr2loop(site.statusList));
p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("pg_list", m.arr2loop(site.pgList));
p.display();

%>