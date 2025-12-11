<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(82, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteDao site = new SiteDao();
UserDeptDao userDept = new UserDeptDao();
UserDao user = new UserDao();
ApiLogDao apiLog = new ApiLogDao();
PaymentDao payment = new PaymentDao();

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
info.put("pay_notice", m.htt(info.s("pay_notice")));

DataSet cinfo = SiteConfig.getDataSet(siteId);
cinfo.put("classroom_notice", m.htt(cinfo.s("classroom_notice")));

//변수
String[] cdnFtp = m.split("|", info.s("cdn_ftp"));
if(3 > cdnFtp.length) cdnFtp = new String[3];
String mode = m.rs("mode");
boolean isMaster = "malgn".equals(loginId);

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
			if(!site.update("id = " + siteId + "")) { m.jsAlert("수료증 배경 이미지를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("certificate_file")));
		}
	} else if("course".equals(m.rs("type"))) {
		if(!"".equals(info.s("course_file"))) {
			site.item("course_file", "");
			if(!site.update("id = " + siteId + "")) { m.jsAlert("수강증 배경 이미지를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("course_file")));
		}
	} else if("certificate_multi".equals(m.rs("type"))) {
		if(!"".equals(info.s("certificate_multi_file"))) {
			site.item("certificate_multi_file", "");
			if(!site.update("id = " + siteId + "")) { m.jsAlert("수료내역서 배경 이미지를 삭제하는 중 오류가 발생했습니다."); return; }
			m.delFileRoot(m.getUploadPath(info.s("certificate_multi_file")));
		}
	}
	return;
}
//API 토큰
if(isMaster) {
	if("api".equals(mode)) {
		String token = Malgn.getUniqId(32);
		site.item("api_token", token);
		if (!site.update("id = " + siteId)) {
			out.print("오류가 발생했습니다.");
			return;
		}
		out.print(token);
		return;
	} else if("apidel".equals(mode)) {
		if (0 > site.execute("UPDATE " + site.table + " SET api_token = NULL WHERE id = ?", new Object[]{siteId})) {
			out.print("오류가 발생했습니다.");
			return;
		}
		out.print("");
		return;
	} else if("sso".equals(mode)) {
		String token = Malgn.getUniqId(16);
		site.item("sso_key", token);
		if (!site.update("id = " + siteId)) {
			out.print("오류가 발생했습니다.");
			return;
		}
		out.print(token);
		return;
	} else if("ssodel".equals(mode)) {
		if (0 > site.execute("UPDATE " + site.table + " SET sso_key = NULL WHERE id = ?", new Object[]{siteId})) {
			out.print("오류가 발생했습니다.");
			return;
		}
		out.print("");
		return;
	}
}

//변수
String siteEmailNm = "";
String siteEmail = info.s("site_email");
if(-1 < siteEmail.indexOf("<")) {
	siteEmailNm = siteEmail.substring(0, siteEmail.indexOf("<")).trim();
	siteEmail = siteEmail.substring(siteEmail.indexOf("<") + 1, siteEmail.indexOf(">")).trim();
}

//폼체크
f.addElement("domain", info.s("domain"), "hname:'도메인', required:'Y'");
f.addElement("site_nm", info.s("site_nm"), "hname:'이름', required:'Y'");
f.addElement("logo", null, "hname:'로고이미지'");
f.addElement("zipcode", info.s("zipcode"), "hname:'우편번호'");
f.addElement("new_addr", info.s("new_addr"), "hname:'주소'");
f.addElement("addr_dtl", info.s("addr_dtl"), "hname:'상세주소'");
f.addElement("join_status", info.i("join_status"), "hname:'회원가입 상태', required:'Y'");
f.addElement("dept_id", info.i("dept_id"), "hname:'기본 회원소속', required:'Y'");
f.addElement("user_auth2_type", info.s("user_auth2_type"), "hname:'사용자단 2차인증방식', required:'Y'");
f.addElement("user_auth2_multitype_yn", SiteConfig.s("user_auth2_multitype_yn"), "hname:'사용자단 2차 인증 다중 타입 사영여부', required:'Y'");
f.addElement("auth2_type", info.s("auth2_type"), "hname:'관리자단 2차인증방식', required:'Y'");
f.addElement("auth2_multitype_yn", SiteConfig.s("auth2_multitype_yn"), "hname:'관리자단 2차 인증 다중 타입 사영여부', required:'Y'");

f.addElement("marketing_yn", SiteConfig.s("agreement_marketing_yn"), "hname:'약관동의 마케팅 사용여부'");
f.addElement("join_birthday_status", SiteConfig.s("join_birthday_status"), "hname:'회원정보 생년월일 상태'");
f.addElement("join_gender_status", SiteConfig.s("join_gender_status"), "hname:'회원정보 성별 상태'");
f.addElement("join_mobile_status", SiteConfig.s("join_mobile_status"), "hname:'회원정보 휴대전화 상태'");
f.addElement("join_email_status", SiteConfig.s("join_email_status"), "hname:'회원정보 이메일 상태'");
f.addElement("join_addr_status", SiteConfig.s("join_addr_status"), "hname:'회원정보 주소 상태'");
f.addElement("join_dept_status", SiteConfig.i("join_dept_status"), "hname:'회원정보 소속 상태'");

f.addElement("modify_user_nm_status", SiteConfig.s("modify_user_nm_status"), "hname:'회원정보 성명 상태'");
f.addElement("modify_birthday_status", SiteConfig.s("modify_birthday_status"), "hname:'회원정보 생년월일 상태'");
f.addElement("modify_gender_status", SiteConfig.s("modify_gender_status"), "hname:'회원정보 성별 상태'");
f.addElement("modify_mobile_status", SiteConfig.s("modify_mobile_status"), "hname:'회원정보 휴대전화 상태'");
f.addElement("modify_email_status", SiteConfig.s("modify_email_status"), "hname:'회원정보 이메일 상태'");
f.addElement("modify_addr_status", SiteConfig.s("modify_addr_status"), "hname:'회원정보 이메일 상태'");
f.addElement("modify_dept_status", SiteConfig.i("modify_dept_status"), "hname:'회원정보 소속 상태'");

f.addElement("etc1", SiteConfig.s("user_etc_nm1"), "hname:'회원정보 기타1'");
f.addElement("etc2", SiteConfig.s("user_etc_nm2"), "hname:'회원정보 기타2'");
f.addElement("etc3", SiteConfig.s("user_etc_nm3"), "hname:'회원정보 기타3'");
f.addElement("etc4", SiteConfig.s("user_etc_nm4"), "hname:'회원정보 기타4'");
f.addElement("etc5", SiteConfig.s("user_etc_nm5"), "hname:'회원정보 기타5'");
f.addElement("join_userfile_yn", SiteConfig.s("join_userfile_yn"), "hname:'가입-파일업로드여부'");
f.addElement("join_userfile_nm", SiteConfig.s("join_userfile_nm"), "hname:'가입-파일업로드명'");
f.addElement("modify_userfile_yn", SiteConfig.s("modify_userfile_yn"), "hname:'수정-파일업로드여부'");
f.addElement("modify_userfile_nm", SiteConfig.s("modify_userfile_nm"), "hname:'수정-파일업로드명'");
f.addElement("site_email", info.s("site_email"), "hname:'발신자이메일'");
f.addElement("site_email_addr", siteEmail, "hname:'발신자이메일', required:'Y'");
f.addElement("site_email_nm", siteEmailNm, "hname:'발신자이메일발신자명'");
f.addElement("receive_email", info.s("receive_email"), "hname:'수신이메일', option:'email'");
f.addElement("receive_phone", info.s("receive_phone"), "hname:'수신전화번호'");
f.addElement("certificate_file", null, "hname:'수료증 배경', allow:'jpg|jpeg|png|gif'");
f.addElement("course_file", null, "hname:'수강증 배경', allow:'jpg|jpeg|png|gif'");
f.addElement("certificate_multi_file", null, "hname:'수료내역서 배경', allow:'jpg|jpeg|png|gif'");
f.addElement("classroom_notice", null, "hname:'강의실상단안내문구', allowhtml:'Y'");
f.addElement("classroom_notice_yn", cinfo.s("classroom_notice_yn"), "hname:'강의실상단안내문구 노출여부'");
f.addElement("pay_notice", null, "hname:'결제페이지안내문구', allowhtml:'Y'");
f.addElement("pay_notice_yn", info.s("pay_notice_yn"), "hname:'결제페이지안내문구 노출여부'");
f.addElement("copyright", null, "hname:'하단HTML', allowhtml:'Y'");
f.addElement("delivery_free_price", cinfo.i("delivery_free_price"), null);
f.addElement("refund_reason_yn", cinfo.s("refund_reason_yn"), "hname:'환불사유 입력여부'");

//f.addElement("session_hour", info.i("session_hour"), "hname:'세션유지시간', required:'Y', option:'number', min:'0'");
//f.addElement("sysop_session_hour", info.i("sysop_session_hour"), "hname:'관리자단세션유지시간(분)', required:'Y', option:'number', min:'0'");
//f.addElement("login_block_cnt", info.i("login_block_cnt"), "hname:'로그인실패차단횟수', required:'Y', option:'number', min:'0'");
//f.addElement("passwd_day", info.s("passwd_day"), "hname:'회원 비밀번호 변경알림 주기', required:'Y', option:'number', min:'0'");

f.addElement("api_token", info.s("api_token"), "hname:'API 엑세스 토큰'");
f.addElement("api_limit", info.i("api_limit"), "hname:'API 월 사용량'");
f.addElement("api_ip_addr", info.s("api_ip_addr"), "hname:'API 허용 IP'");
f.addElement("sso_yn", info.s("sso_yn"), "hname:'SSO 사용여부'");
f.addElement("sso_key", info.s("sso_key"), "hname:'SSO 키'");
f.addElement("sso_url", info.s("sso_url"), "hname:'SSO URL'");
f.addElement("sso_privacy_yn", info.s("sso_privacy_yn"), "hname:'SSO 개인정보동의'");

f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'");
f.addElement("sysop_status", info.i("sysop_status"), "hname:'관리자단 상태', option:'number', required:'Y'");
//f.addElement("duplication_yn", info.s("duplication_yn"), "hname:'사용자단 중복로그인 허용여부', required:'Y'");
//f.addElement("dup_sysop_yn", info.s("dup_sysop_yn"), "hname:'관리자단 중복로그인 허용여부', required:'Y'");
f.addElement("allow_ip_sysop", info.s("allow_ip_sysop"), "hname:'관리자 접근허용IP'");
f.addElement("allow_ip_user", info.s("allow_ip_user"), "hname:'사용자 접근허용IP'");
f.addElement("deny_ip", info.s("deny_ip"), "hname:'사용자 접근차단IP'");
f.addElement("close_yn", info.s("close_yn"), "hname:'폐쇄형 여부', required:'Y'");
f.addElement("close_except", info.s("close_except"), "hname:'폐쇄형 예외페이지'");


//f.addElement("masking_yn", SiteConfig.s("masking_yn"), "hname:'과정설문익명'");
//f.addElement("course_survey_masking_yn", SiteConfig.s("course_survey_masking_yn"), "hname:'과정설문익명'");
f.addElement("target_review_yn", "N".equals(SiteConfig.s("target_review_yn")) ? "N" : "Y", "hname:'신청대상 후기 공개'");
f.addElement("review_reply_yn", "Y".equals(SiteConfig.s("review_reply_yn")) ? "Y" : "N", "hname:'신청대상 후기 공개'");
f.addElement("cert_template_yn", "Y".equals(SiteConfig.s("cert_template_yn")) ? "Y" : "N", "hname:'수료증 템플릿'");
f.addElement("lesson_chat_yn", "Y".equals(SiteConfig.s("lesson_chat_yn")) ? "Y" : "N", "hname:'강의채팅 사용여부'");

f.addElement("ovp_vendor", info.s("ovp_vendor"), "hname:'동영상 공급자', required:'Y'");
f.addElement("doczoom_yn", SiteConfig.s("doczoom_yn"), "hname:'문서(닥줌)', required:'Y'");

f.addElement("video_key", info.s("video_key"), "hname:'동영상 API키'");
f.addElement("video_pkg", info.s("video_pkg"), "hname:'동영상 API키'");
f.addElement("access_token", info.s("access_token"), "hname:'동영상 API키'");
f.addElement("security_key", info.s("security_key"), "hname:'동영상 인증키'");
f.addElement("custom_key", info.s("custom_key"), "hname:'동영상 사용자키'");
f.addElement("kollus_channel", info.s("kollus_channel"), "hname:'동영상 사용자키'");
f.addElement("kollus_clpost_key", SiteConfig.s("kollus_clpost_key"), "hname:'콜러스게시판키'");
f.addElement("kollus_progress_version", !"".equals(SiteConfig.s("kollus_progress_version")) ? SiteConfig.s("kollus_progress_version") : "1", "hname:'iframe 사용', required:'Y'");
f.addElement("download_yn", info.s("download_yn"), "hname:'동영상 다운로드여부', required:'Y'");
f.addElement("kollus_iframe_yn", !"".equals(SiteConfig.s("kollus_iframe_yn")) ? SiteConfig.s("kollus_iframe_yn") : "N", "hname:'iframe 사용', required:'Y'");
f.addElement("kollus_expire_time", !"".equals(SiteConfig.s("kollus_expire_time")) ? SiteConfig.s("kollus_expire_time") : "0", "hname:'OTU 만료시간', required:'Y'");
f.addElement("kollus_playrate_yn", !"".equals(SiteConfig.s("kollus_playrate_yn")) ? SiteConfig.s("kollus_playrate_yn") : "N", "hname:'배속제한 사용여부', required:'Y'");
f.addElement("kollus_live_yn", SiteConfig.s("kollus_live_yn"), "hname:'콜러스 라이브 사용여부', required:'Y'");
f.addElement("kollus_live_security_key", SiteConfig.s("kollus_live_security_key"), "hname:'콜러스 라이브 보안키'");
f.addElement("kollus_live_custom_key", SiteConfig.s("kollus_live_custom_key"), "hname:'콜러스 라이브 사용자키'");
f.addElement("kollus_live_oauth_id", SiteConfig.s("kollus_live_oauth_id"), "hname:'콜러스 라이브 OAuth ID'");
f.addElement("kollus_live_oauth_secret", SiteConfig.s("kollus_live_oauth_secret"), "hname:'콜러스 라이브 OAuth Secret'");
f.addElement("kollus_live_access_token", SiteConfig.s("kollus_live_access_token"), "hname:'콜러스 라이브 Access Token'");
//f.addElement("video_pkg", info.s("video_pkg"), "hname:'위캔디오패키지아이디'");

f.addElement("cdn_ftp_addr", cdnFtp[0], "hname:'CDN FTP 주소'");
f.addElement("cdn_url", info.s("cdn_url"), "hname:'CDN 웹 주소'");
f.addElement("cdn_ftp_id", cdnFtp[1], "hname:'CDN FTP 아이디'");
f.addElement("cdn_ftp_passwd", cdnFtp[2], "hname:'CDN FTP 비밀번호'");
f.addElement("lesson_detect_leave_min", SiteConfig.s("lesson_detect_leave_min"), "hname:'학습 이탈검출'");

f.addElement("sms_yn", info.s("sms_yn"), "hname:'SMS 사용여부', required:'Y'");
f.addElement("sms_sender", info.s("sms_sender"), "hname:'SMS 발신번호'");
f.addElement("sms_id", info.s("sms_id"), "hname:'SMS 아이디'");
f.addElement("sms_pw", info.s("sms_pw"), "hname:'SMS 비밀번호'");
f.addElement("ktalk_yn", !"".equals(SiteConfig.s("ktalk_yn")) ? SiteConfig.s("ktalk_yn") : "N", "hname:'SMS 사용여부', required:'Y'");
f.addElement("ktalk_sender_key", SiteConfig.s("ktalk_sender_key"), "hname:'알림톡 발송키'");

f.addElement("pg_test_yn", info.s("pg_test_yn"), "hname:'서비스상태', required:'Y'");
f.addElement("pg_nm", info.s("pg_nm"), "hname:'결제사', required:'Y'");
f.addElement("pg_id", info.s("pg_id"), "hname:'상점아이디'");
f.addElement("pg_key", info.s("pg_key"), "hname:'상점키'");
f.addElement("pg_month", info.s("pg_month"), "hname:'할부개월', required:'Y', option:'number'");
f.addElement("pg_escrow_yn", info.s("pg_escrow_yn"), "hname:'에스크로 사용여부'");
f.addElement("pay_account", info.s("pay_account"), "hname:'입금계좌/예금주'");
f.addElement("pay_info", info.s("pay_info"), "hname:'입금안내'");

f.addElement("auth_yn", info.s("auth_yn"), "hname:'본인인증사용여부'");
//f.addElement("auth_type", info.s("auth_type"), "hname:'본인인증유형'");
f.addElement("auth_code", info.s("auth_code"), "hname:'본인인증사이트코드'");
f.addElement("auth_passwd", info.s("auth_passwd"), "hname:'본인인증사이트비밀번호'");
f.addElement("auth_login_yn", info.s("auth_login_yn"), "hname:'본인인증로그인사용여부'");

f.addElement("ipin_yn", info.s("ipin_yn"), "hname:'아이핀인증사용여부'");
f.addElement("ipin_code", info.s("ipin_code"), "hname:'아이핀인증사이트코드'");
f.addElement("ipin_passwd", info.s("ipin_passwd"), "hname:'아이핀인증사이트비밀번호'");

if(isMaster) {
	f.addElement("allow_masking_yn", SiteConfig.s("allow_masking_yn"), "hname:'개인정보 공개 허용 여부'");
	f.addElement("sys_viewer_version", Math.max(SiteConfig.i("sys_viewer_version"), 1), "hname:'학습창뷰어버전'");
	f.addElement("sys_ai_chat_yn", SiteConfig.s("sys_ai_chat_yn"), "hname:'AI채팅사용여부'");
	f.addElement("sys_viewer_comment_yn", SiteConfig.s("sys_viewer_comment_yn"), "hname:'대댓글기능사용여부'");
	f.addElement("verify_email_yn", "Y".equals(info.s("verify_email_yn")) ? info.s("verify_email_yn") : "N", "hname:'이메일인증 여부', required:'Y'");
}

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
	site.item("join_status", f.getInt("join_status"));
	site.item("zipcode", f.get("zipcode"));
	site.item("new_addr", f.get("new_addr"));
	site.item("addr_dtl", f.get("addr_dtl"));

	site.item("pay_notice", f.get("pay_notice"));
	site.item("pay_notice_yn", f.get("pay_notice_yn"));

	//site.item("site_email", f.get("site_email"));
	site.item("site_email", f.get("site_email_nm") + " <" + f.get("site_email_addr") + ">");
	site.item("receive_email", f.get("receive_email"));
	site.item("receive_phone", f.get("receive_phone"));

	if(null != f.getFileName("certificate_file")) {
		File f1 = f.saveFile("certificate_file");
		if(f1 != null) {
			site.item("certificate_file", f.getFileName("certificate_file"));
			m.delFileRoot(m.getUploadPath(info.s("certificate_file")));
		}
	}
	if(null != f.getFileName("course_file")) {
		File f1 = f.saveFile("course_file");
		if(f1 != null) {
			site.item("course_file", f.getFileName("course_file"));
			m.delFileRoot(m.getUploadPath(info.s("course_file")));
		}
	}
	if(null != f.getFileName("certificate_multi_file")) {
		File f1 = f.saveFile("certificate_multi_file");
		if(f1 != null) {
			site.item("certificate_multi_file", f.getFileName("certificate_multi_file"));
			m.delFileRoot(m.getUploadPath(info.s("certificate_multi_file")));
		}
	}

	site.item("dept_id", f.getInt("dept_id"));


	site.item("sysop_status", f.getInt("sysop_status"));
	site.item("status", f.getInt("status"));
	site.item("duplication_yn", "N");
	site.item("dup_sysop_yn", "N");
	site.item("allow_ip_sysop", f.get("allow_ip_sysop"));
	site.item("allow_ip_user", f.get("allow_ip_user"));
	site.item("deny_ip", f.get("deny_ip"));
	site.item("passwd_day", 90);
	site.item("session_hour", 2);
	site.item("sysop_session_hour", 120);
	site.item("login_block_cnt", 5);

	site.item("close_yn", f.get("close_yn"));
	site.item("close_except", f.get("close_except"));

	site.item("ovp_vendor", f.get("ovp_vendor"));

	site.item("video_key", f.get("video_key"));
	site.item("video_pkg", f.get("video_pkg"));
	site.item("access_token", f.get("access_token"));
	site.item("security_key", f.get("security_key"));
	site.item("custom_key", f.get("custom_key"));
	site.item("kollus_channel", f.get("kollus_channel"));
	site.item("download_yn", f.get("download_yn"));

	site.item("sms_yn", f.get("sms_yn"));
	site.item("sms_sender", f.get("sms_sender"));
	site.item("sms_id", f.get("sms_id"));
	site.item("sms_pw", f.get("sms_pw"));

	site.item("pg_nm", f.get("pg_nm"));
	site.item("pg_id", f.get("pg_id"));
	site.item("pg_key", f.get("pg_key"));
	site.item("pg_escrow_yn", f.get("pg_escrow_yn", "N"));
	site.item("pg_methods", "|" + m.join("|", f.getArr("pg_methods")) + "|");
	site.item("pg_month", f.getInt("pg_month"));
	site.item("pg_test_yn", f.get("pg_test_yn"));
	site.item("pay_account", f.get("pay_account"));
	site.item("pay_info", f.get("pay_info"));
	site.item("pay_notice", f.get("pay_notice"));
	site.item("pay_notice_yn", f.get("pay_notice_yn"));

	site.item("cdn_ftp", f.glue("|", "cdn_ftp_addr,cdn_ftp_id,cdn_ftp_passwd"));
	site.item("cdn_url", f.get("cdn_url"));

	site.item("auth_yn", f.get("auth_yn"));
	site.item("auth_login_yn", f.get("auth_login_yn"));
	site.item("auth_code", f.get("auth_code"));
	site.item("auth_passwd", f.get("auth_passwd"));

	site.item("ipin_yn", f.get("ipin_yn"));
	site.item("ipin_code", f.get("ipin_code"));
	site.item("ipin_passwd", f.get("ipin_passwd"));

	site.item("user_auth2_type", f.get("user_auth2_type"));
	site.item("auth2_type", f.get("auth2_type"));
	
	site.item("sso_yn", f.get("sso_yn", "N"));
	site.item("sso_url", f.get("sso_url"));
	site.item("sso_privacy_yn", f.get("sso_privacy_yn", "N"));
	site.item("api_ip_addr", f.get("api_ip_addr"));
	if(isMaster) {
		site.item("verify_email_yn", f.get("verify_email_yn", "N"));
		site.item("api_limit", f.get("api_limit"));
	}

	if(!site.update("id = " + siteId + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; 	}

	SiteConfig.put("agreement_marketing_yn", f.get("marketing_yn"));

	SiteConfig.put("join_birthday_status", f.get("join_birthday_status"));
	SiteConfig.put("join_gender_status", f.get("join_gender_status"));
	SiteConfig.put("join_mobile_status", f.get("join_mobile_status"));
	SiteConfig.put("join_email_status", f.get("join_email_status"));
	SiteConfig.put("join_addr_status", f.get("join_addr_status"));
	SiteConfig.put("join_dept_status", f.get("join_dept_status"));

	SiteConfig.put("modify_user_nm_status", f.get("modify_user_nm_status"));
	SiteConfig.put("modify_birthday_status", f.get("modify_birthday_status"));
	SiteConfig.put("modify_gender_status", f.get("modify_gender_status"));
	SiteConfig.put("modify_mobile_status", f.get("modify_mobile_status"));
	SiteConfig.put("modify_email_status", f.get("modify_email_status"));
	SiteConfig.put("modify_addr_status", f.get("modify_addr_status"));

	SiteConfig.put("user_auth2_multitype_yn", f.get("user_auth2_multitype_yn"));
	SiteConfig.put("auth2_multitype_yn", f.get("auth2_multitype_yn"));

	SiteConfig.put("user_etc_nm1", f.get("etc1"));
	SiteConfig.put("user_etc_nm2", f.get("etc2"));
	SiteConfig.put("user_etc_nm3", f.get("etc3"));
	SiteConfig.put("user_etc_nm4", f.get("etc4"));
	SiteConfig.put("user_etc_nm5", f.get("etc5"));

	SiteConfig.put("join_userfile_yn", f.get("join_userfile_yn"));
	SiteConfig.put("join_userfile_nm", f.get("join_userfile_nm"));
	SiteConfig.put("modify_userfile_yn", f.get("modify_userfile_yn"));
	SiteConfig.put("modify_userfile_nm", f.get("modify_userfile_nm"));

	SiteConfig.put("delivery_free_price", f.getInt("delivery_free_price"));
	SiteConfig.put("refund_reason_yn", f.get("refund_reason_yn", "N"));

	SiteConfig.put("classroom_notice_yn", f.get("classroom_notice_yn", "N"));
	SiteConfig.put("classroom_notice", f.get("classroom_notice"));

	SiteConfig.put("masking_yn", "Y");
	SiteConfig.put("course_survey_masking_yn", "N");

	SiteConfig.put("target_review_yn", f.get("target_review_yn", "Y"));
	SiteConfig.put("review_reply_yn", f.get("review_reply_yn", "N"));
	SiteConfig.put("cert_template_yn", f.get("cert_template_yn", "N"));
	SiteConfig.put("lesson_chat_yn", f.get("lesson_chat_yn", "N"));

	SiteConfig.put("doczoom_yn", f.get("doczoom_yn", "N"));
	SiteConfig.put("kollus_clpost_key", f.get("kollus_clpost_key"));
	SiteConfig.put("kollus_progress_version", f.get("kollus_progress_version", "1"));
	SiteConfig.put("kollus_iframe_yn", f.get("kollus_iframe_yn", "N"));
	SiteConfig.put("kollus_expire_time", f.getInt("kollus_expire_time"));
	SiteConfig.put("kollus_playrate_yn", f.get("kollus_playrate_yn", "N"));
	SiteConfig.put("kollus_live_yn", f.get("kollus_live_yn", "N"));
	SiteConfig.put("kollus_live_security_key", f.get("kollus_live_security_key"));
	SiteConfig.put("kollus_live_custom_key", f.get("kollus_live_custom_key"));
	SiteConfig.put("kollus_live_oauth_id", f.get("kollus_live_oauth_id"));
	SiteConfig.put("kollus_live_oauth_secret", f.get("kollus_live_oauth_secret"));
	SiteConfig.put("kollus_live_channel_key", f.get("kollus_live_channel_key"));
	SiteConfig.put("kollus_live_channel_code", f.get("kollus_live_channel_code"));
	SiteConfig.put("lesson_detect_leave_min", f.get("lesson_detect_leave_min"));

	SiteConfig.put("ktalk_yn", f.get("ktalk_yn"));
	SiteConfig.put("ktalk_sender_key", f.get("ktalk_sender_key"));

	if("malgn".equals(loginId)) {
		SiteConfig.put("allow_masking_yn", f.get("allow_masking_yn"));
		SiteConfig.put("sys_viewer_version", f.getInt("sys_viewer_version", 1));
		SiteConfig.put("sys_ai_chat_yn", f.get("sys_ai_chat_yn", "N"));
		SiteConfig.put("sys_viewer_comment_yn", f.get("sys_viewer_comment_yn", "N"));
	}

	//캐쉬 삭제
	site.remove(info.s("domain"));
	if(!"".equals(info.s("domain2"))) site.remove(info.s("domain2"));

	SiteConfig.remove(siteId + "");

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

info.put("certificate_multi_file_conv", m.encode(info.s("certificate_multi_file")));
info.put("certificate_multi_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(info.s("certificate_multi_file")));
info.put("certificate_multi_file_ek", m.encrypt(info.s("certificate_multi_file") + m.time("yyyyMMdd")));

info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

info.put("ovp_vendor_conv", m.getItem(info.s("ovp_vendor"), site.ovpVendors));
info.put("catenoid_block", "C".equals(info.s("ovp_vendor")));

//출력
p.setBody("site.site_info");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("cinfo", cinfo);
p.setVar("modify", true);
p.setVar("master_block", isMaster);

p.setLoop("ovp_vendor_list", m.arr2loop(site.ovpVendors));
p.setLoop("methods", m.arr2loop(payment.methods));

p.setLoop("status_list", m.arr2loop(site.statusList));
p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("pg_list", m.arr2loop(site.pgList));
p.display();

%>