<%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*" %><%

request.setCharacterEncoding("UTF-8");

final String BUILDVERSION = "24.02.01";

String docRoot = Config.getDocRoot();
String jndi = Config.getJndi();

Malgn m = new Malgn(request, response, out);

Form f = new Form("form1");
try { f.setRequest(request); }
catch(RuntimeException re) {
	m.errorLog("Overflow file size. - " + re.getMessage(), re);
	return;
}
catch(Exception ex) {
	m.errorLog("Overflow file size. - " + ex.getMessage(), ex);
	return;
}

SiteDao Site = new SiteDao(); //Site.clear();
DataSet siteinfo = Site.getSiteInfo(request.getServerName());
SiteConfigDao SiteConfig = new SiteConfigDao(siteinfo.i("id"));
if(1 != siteinfo.i("status") || "".equals(siteinfo.s("doc_root"))) {
	//m.jsReplace("about:blank", "top");
	return;
}

//CSAP 기준 로그인 실패 횟수 5회
siteinfo.put("login_block_cnt", 5);
//CSAP 기준 비밀번호 만료일 90일
siteinfo.put("passwd_day", 90);
//CSAP 소셜 로그인 사용 안함
siteinfo.put("oauth_vendor", "");
//중복로그인 허용하지 않음
siteinfo.put("duplication_yn", "N");
siteinfo.put("dup_sysop_yn", "N");
//게시판 마스킹 함
siteinfo.put("masking_yn", "Y");
//설문 마스킹 안함
siteinfo.put("course_survey_masking_yn", "N");
//세션 유지시간 1시간
siteinfo.put("session_hour", 1);
//결제페이지 안내 문구
String allowTags = "a,b,br,cite,code,dd,dl,dt,div,em,i,li,ol,p,pre,q,small,span,strike,strong,sub,sup,u,ul,article,aside,details,div,dt,figcaption,footer,form,fieldset,header,hgroup,html,main,nav,section,summary,body,p,dl,multicol,dd,figure,address,center,blockquote,h1,h2,h3,h4,h5,h6,listing,xmp,pre,plaintext,menu,dir,ul,ol,li,hr,table,tbody,thead,tfoot,th,tr,td,caption,textarea,img,input,textarea,hr,iframe,video,audio";
String allowRegexr = "<(\\/?)(?!.*" + Malgn.replace(allowTags, ",", "[ >]|.*") + "[ >])([^>]*)>";
siteinfo.put("pay_notice", siteinfo.s("pay_notice").replaceAll(allowRegexr, "&lt;$1$2&gt;"));
siteinfo.put("pay_notice", siteinfo.s("pay_notice").replaceAll(" on([^\\t\\n\\f\\- \\/>\"'=]+\\s*)=", " on-$1="));

siteinfo.put("copyright", siteinfo.s("copyright").replaceAll(allowRegexr, "&lt;$1$2&gt;"));
siteinfo.put("copyright", siteinfo.s("copyright").replaceAll(" on([^\\t\\n\\f\\- \\/>\"'=]+\\s*)=", " on-$1="));

//Hashtable<String, String> siteconfig = SiteConfig.getSiteConfig(siteinfo.s("id"));
boolean isDevServer = -1 < request.getServerName().indexOf("politech.malgn.co.kr");
String webUrl = request.getScheme() + "://" + request.getServerName();
int port = request.getServerPort();
if(port != 80 && port != 443) webUrl += ":" + port;
String dataDir = siteinfo.s("doc_root") + "/data";
String tplRoot = siteinfo.s("doc_root") + "/html";
f.dataDir = dataDir;
m.dataDir = dataDir;
m.dataUrl = Config.getDataUrl();

if(!"".equals(siteinfo.s("logo"))) siteinfo.put("logo_url", m.getUploadUrl(siteinfo.s("logo")));
else siteinfo.put("logo_url", "/common/images/default/malgn_logo.jpg");

//IP차단
//String userIp = request.getRemoteAddr();
String userIp = m.getRemoteAddr();
if(!"".equals(siteinfo.s("allow_ip_user")) && !Site.checkIP(userIp, siteinfo.s("allow_ip_user"))) {
	m.redirect("/main/guide.jsp");
	return;
}

Page p = new Page(tplRoot);
p.setRequest(request);
p.setPageContext(pageContext);
p.setWriter(out);
p.setBaseRoot("C:/Users/newkl/Desktop/MalgnLMS/public_html/html");

//언어
String sysLocale = "".equals(siteinfo.s("locale")) ? "default" : siteinfo.s("locale");
Message _message = new Message(sysLocale);
_message.reloadAll();
m.setMessage(_message);
//p.setMessage(_message);

int siteId = siteinfo.i("id");
int userId = 0;
String loginId = "";
String loginMethod = "";
String userName = "";
String userEmail = "";
String userKind = "";
int userDeptId = 0;
String userGroups = "";
int userGroupDisc = 0;
//String aloginYn = "";
String userSessionId = "";
boolean userB2BBlock = false;
String userB2BName = "";
String userB2BFile = "";
String sysToday = m.time("yyyyMMdd");
String sysNow = m.time("yyyyMMddHHmmss");
boolean isRespWeb = (5 <= siteinfo.i("skin_cd"));
boolean isGoMobile = !isRespWeb && m.isMobile();
int sysViewerVersion = Math.max(SiteConfig.i("sys_viewer_version"), 1);
boolean sysViewerComment = "Y".equals(SiteConfig.s("sys_viewer_comment_yn"));

SessionDao mSession = new SessionDao(request, response);

DataSet auth2Info = Config.getDataSet("//config/userAuth2");
auth2Info.next();

Auth auth = new Auth(request, response);
auth.loginURL = "/member/login.jsp";
auth.keyName = "MLMS14" + siteId + "7";
if(0 < siteinfo.i("session_hour")) auth.setValidTime(siteinfo.i("session_hour") * 3600);
if(auth.isValid()) {
	userId = auth.getInt("ID");
	loginId = auth.getString("LOGINID");
	loginMethod = auth.getString("LOGINMETHOD");
	userName = auth.getString("NAME");
	userEmail = auth.getString("EMAIL");
	userKind = auth.getString("KIND");
	userDeptId = auth.getInt("DEPT");
	userGroups = auth.getString("GROUPS");
	userGroupDisc = !"null".equals(auth.getString("GROUPS_DISC")) ? m.parseInt(auth.getString("GROUPS_DISC")) : 0;
	//aloginYn = auth.getString("ALOGIN_YN");
	userSessionId = auth.getString("SESSIONID");
	userB2BName = auth.getString("B2BNAME");
	userB2BFile = auth.getString("B2BFILE");
	if(userGroups != null) {
		if(-1 < userGroups.indexOf(",")) for(String userGroupId : m.split(",", userGroups)) p.setVar("SYS_USERGROUP_" + userGroupId, true);
		else p.setVar("SYS_USERGROUP_" + userGroups, true);
	}

	//2차인증체크
	if("direct".equals(loginMethod)
		&& "Y".equals(auth2Info.s("auth2Yn"))
		&& !"Y".equals(auth.getString("USER_AUTH2_YN"))
		&& "Y".equals(auth.getString("DEPT_AUTH2_YN")) //관리자단-회원소속관리에서 2차인증설정 여부 Y/N	 20230126
		//&& !"".equals(auth.getString("USER_AUTH2_TYPE"))
		//&& !"malgn".equals(loginId)
		&& !request.getRequestURI().startsWith("/main/site_cache.jsp")
		&& !request.getRequestURI().startsWith("/member/auth2.jsp")
		&& !request.getRequestURI().startsWith("/member/otpkey_register.jsp")
		&& !request.getRequestURI().startsWith("/member/logout.jsp")
		&& !request.getRequestURI().startsWith("/member/alogin.jsp")
		&& !request.getRequestURI().startsWith("/member/slogin.jsp")
		&& !request.getRequestURI().startsWith("/member/login_facebook.jsp")
		&& !request.getRequestURI().startsWith("/member/login_google.jsp")
		&& !request.getRequestURI().startsWith("/member/login_kakao.jsp")
		&& !request.getRequestURI().startsWith("/member/login_line.jsp")
		&& !request.getRequestURI().startsWith("/member/login_naver.jsp")
		&& !request.getRequestURI().startsWith("/classroom/attend_insert.jsp")
		&& !request.getRequestURI().startsWith("/mypage/modify_passwd.jsp")
	) {
		m.jsReplace("/member/auth2.jsp?returl=" + Malgn.urlencode(m.getThisURI()), "top");
		return;
	}

	//비밀번호 변경 안함
	if(
		"N".equals(auth.getString("MODIFY_PASSWD"))
		&& !request.getRequestURI().startsWith("/member/logout.jsp")
		&& !request.getRequestURI().startsWith("/member/login.jsp")
		&& !request.getRequestURI().startsWith("/mypage/modify_passwd.jsp")
	) {
		m.jsReplace("/member/logout.jsp");
		return;
	}

	if(
		(
			(1 < SiteConfig.i("join_birthday_status") && "".equals(auth.getString("BIRTHDAY"))) //생년월일
			|| (1 < SiteConfig.i("join_gender_status") && "".equals(auth.getString("GENDER"))) //성별
			|| (1 < SiteConfig.i("join_mobile_status") && "".equals(auth.getString("MOBILE"))) //휴대전화번호
			|| ("".equals(auth.getString("NAME"))) //성명
			|| ("".equals(auth.getString("EMAIL"))) //이메일
		)
		&& !request.getRequestURI().startsWith("/member/logout.jsp")
		&& !request.getRequestURI().startsWith("/member/login.jsp")
		&& !request.getRequestURI().startsWith("/member/privacy_agree.jsp")
		&& !request.getRequestURI().startsWith("/mypage/modify.jsp")
		&& !request.getRequestURI().startsWith("/mypage/modify_verify.jsp")
		&& !request.getRequestURI().startsWith("/main/site_cache.jsp")
		&& !request.getRequestURI().startsWith("/member/auth2.jsp")
		&& !request.getRequestURI().startsWith("/member/otpkey_register.jsp")
		&& !request.getRequestURI().startsWith("/member/alogin.jsp")
		&& !request.getRequestURI().startsWith("/member/slogin.jsp")
		&& !request.getRequestURI().startsWith("/member/login_facebook.jsp")
		&& !request.getRequestURI().startsWith("/member/login_google.jsp")
		&& !request.getRequestURI().startsWith("/member/login_kakao.jsp")
		&& !request.getRequestURI().startsWith("/member/login_line.jsp")
		&& !request.getRequestURI().startsWith("/member/login_naver.jsp")
		&& !request.getRequestURI().startsWith("/classroom/attend_insert.jsp")
		&& !request.getRequestURI().startsWith("/mypage/modify_passwd.jsp")
	) {
		int tut = m.getUnixTime();
		String tek = m.encrypt(tut + "|" + loginId + "|7B1F83A608723CEDDFA9AED338FC796C", "SHA-256");
		String noInfoString = "";

		if(1 < SiteConfig.i("join_birthday_status") && "".equals(auth.getString("BIRTHDAY"))) noInfoString = "생년월일";
		else if(1 < SiteConfig.i("join_gender_status") && "".equals(auth.getString("GENDER"))) noInfoString = "성별";
		else if(1 < SiteConfig.i("join_mobile_status") && "".equals(auth.getString("MOBILE"))) noInfoString = "휴대전화번호";
		else if("".equals(auth.getString("NAME"))) noInfoString = "성명";
		else if("".equals(auth.getString("EMAIL"))) noInfoString = "이메일";
		m.jsAlert("회원 필수 정보 [" + noInfoString + "](이)가 누락되어\\n수정페이지로 이동합니다.");
		m.jsReplace("/mypage/modify.jsp?ek=" + tek + "&ut=" + tut);
		return;
	}

	mSession.put("id", userSessionId);
	mSession.save();

	p.setVar("login_block", true);
} else {
	p.setVar("login_block", false);

	if(siteinfo.b("close_yn")) {
		boolean isNeedLogin = true;
		String[] exceptPages = m.split("|", siteinfo.s("close_except"));

		if(-1 < request.getRequestURI().indexOf("/member/login.jsp")
			|| -1 < request.getRequestURI().indexOf("/member/find.jsp")
			|| -1 < request.getRequestURI().indexOf("/member/alogin.jsp")
			|| -1 < request.getRequestURI().indexOf("/member/slogin.jsp")
			|| -1 < request.getRequestURI().indexOf("/member/slogin_input.jsp")
			|| -1 < request.getRequestURI().indexOf("/member/sysop_slogin.jsp")
			|| -1 < request.getRequestURI().indexOf("/main/site_cache.jsp")
			|| -1 < request.getRequestURI().indexOf("/mobile/login.jsp")
			|| -1 < request.getRequestURI().indexOf("/mypage/certificate.jsp")
			|| -1 < request.getRequestURI().indexOf("/mypage/certificate_course.jsp")
			|| -1 < request.getRequestURI().indexOf("/kollus/check_api.jsp")
			|| -1 < request.getRequestURI().indexOf("/common/")
			|| -1 < request.getRequestURI().indexOf("/api/auto_send.jsp")
		) {
			isNeedLogin = false;
		} else if(!"".equals(siteinfo.s("close_except"))) {
			for(int i = 0; i < exceptPages.length; i++) {
				if(-1 < request.getRequestURI().indexOf(exceptPages[i])) { isNeedLogin = false; continue; }
			}
		}

		if(isNeedLogin) {
			m.redirect(!isGoMobile ? auth.loginURL : "/mobile/login.jsp");
			return;
		}
	}
}

userB2BBlock = !"".equals(userB2BName) && null != userB2BName;
p.setVar("SYS_HTTPHOST", request.getServerName());
p.setVar("SYS_LOGINID", loginId);
p.setVar("SYS_USERID", userId);
p.setVar("SYS_USERNAME", userName);
p.setVar("SYS_USEREMAIL", userEmail);
p.setVar("SYS_USERKIND", userKind);
p.setVar("SYS_DEPTID", userDeptId);
p.setVar("SYS_GROUP_DISC", userGroupDisc);
p.setVar("SYS_B2BBLOCK", userB2BBlock);
p.setVar("SYS_B2BNAME", userB2BName);
p.setVar("SYS_B2BFILE", userB2BFile);
p.setVar("SYS_PAGE_URL", request.getRequestURL() + (!"".equals(m.qs()) ? "?" + m.qs() : ""));
p.setVar("SYS_TITLE", siteinfo.s("site_nm"));
p.setVar("webUrl", webUrl);
p.setVar("SITE_INFO", siteinfo);
//p.setVar("SITE_CONFIG", siteconfig);
p.setVar("CURR_DATE", m.time("yyyyMMdd"));
p.setVar("SYS_EK", m.encrypt(loginId + siteinfo.s("sso_key") + m.time("yyyyMMdd"), "SHA-256"));
p.setVar("IS_RESP_WEB", isRespWeb);
p.setVar("IS_MOBILE", m.isMobile());
p.setVar("IS_GO_MOBILE", isGoMobile);
p.setVar("IS_DEV_SERVER", isDevServer);
p.setVar("SYS_LOCALE", sysLocale);
p.setVar("SYS_TODAY", sysToday);
p.setVar("SYS_NOW", sysNow);
//p.setVar("SYS_COMMON_CDN", !isDevServer ? "//cdn.malgnlms.com" : "");
p.setVar("SYS_VIEWER_VERSION", sysViewerVersion);
p.setVar("SYS_VIEWER_COMMENT", sysViewerComment);
p.setVar("script", siteinfo.s("header_script"));

for(int IndexSkin = 1; IndexSkin < 5; IndexSkin++) {
	p.setVar("SKIN_LT_" + IndexSkin, siteinfo.i("skin_cd") < IndexSkin);
	p.setVar("SKIN_LTE_" + IndexSkin, siteinfo.i("skin_cd") <= IndexSkin);
	p.setVar("SKIN_GT_" + IndexSkin, siteinfo.i("skin_cd") > IndexSkin);
	p.setVar("SKIN_GTE_" + IndexSkin, siteinfo.i("skin_cd") >= IndexSkin);
}

MenuDao Menu = new MenuDao(p, sysLocale);

UserSessionDao UserSession = new UserSessionDao();
UserSession.setSiteId(siteId);
if(userId != 0 && !"SYSLOGIN".equals(userSessionId) && !siteinfo.b("duplication_yn") && !UserSession.isValid(userSessionId, userId)) {
	if(request.getRequestURI().indexOf("/member/logout.jsp") == -1 && request.getRequestURI().indexOf("/mobile/logout.jsp") == -1) {
		m.jsAlert(_message.get("alert.common.logout_session"));
		if(request.getRequestURI().indexOf("/mobile/") != -1) m.jsReplace("/mobile/logout.jsp?mode=session");
		else m.jsReplace("/member/logout.jsp?mode=session");
		return;
	}
}

%>
