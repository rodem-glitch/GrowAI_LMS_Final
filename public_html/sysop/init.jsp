<%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*" %><%

request.setCharacterEncoding("UTF-8");

String docRoot = Config.getDocRoot();
String jndi = Config.getJndi();
String tplRoot = Config.getDocRoot() + "/sysop/html";

Malgn m = new Malgn(request, response, out);

Form f = new Form("form1");
try { f.setRequest(request); }
catch (RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage()); return; }
catch (Exception ex) { m.errorLog("제한 용량 초과 - " + ex.getMessage()); return; }

Page p = new Page(tplRoot);
p.setRequest(request);
p.setPageContext(pageContext);
p.setWriter(out);
p.setBaseRoot("/home/lms/public_html/html");

SiteDao Site = new SiteDao();
DataSet siteinfo = Site.getSiteInfo(request.getServerName(), "sysop");
SiteConfigDao SiteConfig = new SiteConfigDao(siteinfo.i("id"));
if(1 != siteinfo.i("sysop_status") || "".equals(siteinfo.s("doc_root"))) { m.jsReplace("/main/guide.jsp", "top"); return; }
//Hashtable<String, String> siteconfig = SiteConfig.getSiteConfig(siteinfo.s("id"));

//CSAP 기준 로그인 실패 횟수 5회
siteinfo.put("login_block_cnt", 5);
//CSAP 기준 비밀번호 만료일 90일
siteinfo.put("passwd_day", 90);
//중복로그인 허용하지 않음
siteinfo.put("duplication_yn", "N");
siteinfo.put("dup_sysop_yn", "N");
//게시판 마스킹 함
siteinfo.put("masking_yn", "Y");
//설문 마스킹 안함
siteinfo.put("course_survey_masking_yn", "N");
//세션 유지시간 60분
siteinfo.put("sysop_session_hour", 60);
//B2b사용X
SiteConfig.put("join_b2b_yn", "N");

//String siteDomain = request.getScheme() + "://" + request.getServerName();
String siteDomain = "https://" + request.getServerName();
/*int port = request.getServerPort();
if(port != 80) siteDomain += ":" + port;*/
String webUrl = siteDomain + "/sysop";

String dataDir = siteinfo.s("doc_root") + "/data";
f.dataDir = dataDir;
m.dataDir = dataDir;
//m.dataUrl = Config.getDataUrl() + (!"/data".equals(Config.getDataUrl()) ? siteinfo.s("ftp_id") : "");
m.dataUrl = Config.getDataUrl();

boolean isDevServer = -1 < request.getServerName().indexOf("lms.malgn.co.kr");
siteinfo.put("logo_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(siteinfo.s("logo")));

//IP차단
//String userIp = request.getRemoteAddr();
String userIp = m.getRemoteAddr(); //Lb 사용
if(userIp.contains(",")) {
	String[] userIpArr = m.split(",", userIp);
	userIp = userIpArr[0].trim();
}

boolean isMalgnOffice = "1.212.252.90|3.35.211.181|52.79.184.225|127.0.0.1".contains(userIp);
isMalgnOffice = true;
//if(!"".equals(siteinfo.s("allow_ip_sysop")) && !isMalgnOffice && !Site.checkIP(userIp, siteinfo.s("allow_ip_sysop"))) {
//	m.redirect("/");
//	return;
//}

//언어
String sysLocale = "".equals(siteinfo.s("locale")) ? "default" : siteinfo.s("locale");
//String sysLocale = "default";
Message _message = new Message(sysLocale);
_message.reloadAll();
m.setMessage(_message);
//p.setMessage(_message);

//기본 회원정보
int siteId = siteinfo.i("id");
int userId = 0;
String loginId = "";
String userName = "";
String userKind = "";
int userDeptId = 0;
String userGroups = "";
String manageCourses = "";
String userSessionId = "";
String pagreeDate = "";
boolean isUserMaster = false;
String winTitle = "[관리자] " + siteinfo.s("site_nm");
String sysToday = m.time("yyyyMMdd");
String sysNow = m.time("yyyyMMddHHmmss");
String surl = request.getRequestURL() + (!"".equals(m.qs()) ? "?" + m.qs() : "");
int sysViewerVersion = Math.max(SiteConfig.i("sys_viewer_version"), 1);
boolean sysViewerComment = "Y".equals(SiteConfig.s("sys_viewer_comment_yn"));
final int sysExcelCnt = 20000;

SessionDao mSession = new SessionDao(request, response);

//로그인 여부를 체크
Auth auth = new Auth(request, response);
auth.loginURL = "/sysop/main/login.jsp";
auth.keyName = "MLMSKEY2014" + siteId + "7";
if(0 < siteinfo.i("sysop_session_hour")) auth.setValidTime(siteinfo.i("sysop_session_hour") * 60);
if(auth.isValid()) {
	userId = m.parseInt(auth.getString("ID"));
	loginId = auth.getString("LOGINID");
	userName = auth.getString("NAME");
	userKind = auth.getString("KIND");
	userDeptId = auth.getInt("DEPT");
	userGroups = auth.getString("GROUPS");
	manageCourses = auth.getString("MANAGE_COURSES");
	userSessionId = userSessionId = auth.getString("SESSIONID");
	pagreeDate = auth.getString("PAGREE_DATE");
	isUserMaster = "Y".equals(auth.getString("IS_USER_MASTER"));

	//2차인증체크
	if(request.getRequestURI().indexOf("/main/auth2.jsp") == -1
		//&& "Y".equals(siteinfo.s("auth2_yn"))
		&& !"Y".equals(auth.getString("AUTH2_YN"))
		//&& !"".equals(siteinfo.s("auth2_type"))
		//&& !"malgn".equals(loginId)
		&& request.getRequestURI().indexOf("/main/otpkey_register.jsp") == -1
		&& request.getRequestURI().indexOf("/sysop/main/logout.jsp") == -1
		&& request.getRequestURI().indexOf("/main/modify_passwd.jsp") == -1
	) {
		m.jsReplace("/sysop/main/auth2.jsp?returl=" + m.rs("returl", "/sysop/index.jsp"), "top");
		return;
	}

	//비밀번호 변경 안함
	if(
		"N".equals(auth.getString("MODIFY_PASSWD"))
		&& -1 == request.getRequestURI().indexOf("/sysop/main/logout.jsp")
		&& -1 == request.getRequestURI().indexOf("/sysop/main/login.jsp")
		&& -1 == request.getRequestURI().indexOf("/main/modify_passwd.jsp")
	) {
		m.jsReplace("/sysop/main/logout.jsp");
		return;
	}

	mSession.put("id", userSessionId);
	mSession.save();

} else {
	if(request.getRequestURI().indexOf("/main/login.jsp") == -1
		&& request.getRequestURI().indexOf("/vod/upload.jsp") == -1
		&& request.getRequestURI().indexOf("/main/slogin.jsp") == -1
		&& request.getRequestURI().indexOf("/site/site_template.jsp") == -1
		&& request.getRequestURI().indexOf("/site/site_maildir.jsp") == -1
		&& (request.getRequestURI().indexOf("/user/sleep_insert.jsp") == -1 || !"log".equals(m.rs("after")))
	) {
		m.jsReplace(auth.loginURL, "top");
		return;
	}
}

MenuDao Menu = new MenuDao(p, siteId, "default");
SiteMenuDao SiteMenu = new SiteMenuDao();

boolean superBlock = "S".equals(userKind);
boolean adminBlock = "S".equals(userKind) || "A".equals(userKind);
boolean courseManagerBlock = "C".equals(userKind);
boolean deptManagerBlock = "D".equals(userKind);

//boolean isAuthCrm = superBlock || (-1 < siteinfo.s("auth_crm").indexOf("|" + userKind + "|"));
boolean isAuthCrm = superBlock || Menu.accessible(-999, userId, userKind, false);

//로그아웃-과정운영자
if(courseManagerBlock && "".equals(manageCourses) && request.getRequestURI().indexOf("/main/logout.jsp") == -1) {
	m.jsAlert("담당한 과정이 없습니다.\\n 관리자에게 문의하세요.");
	m.jsReplace("/sysop/main/logout.jsp", "top");
	return;
}

//매뉴얼
ManualDao Manual = new ManualDao();
int ManualId = Menu.getOneInt("SELECT manual_id FROM " + Menu.table + " WHERE link = '" + m.replace(request.getRequestURI(), "/sysop", "..") + "'");
if(0 < ManualId) {
	int ManualStatus = Manual.getOneInt("SELECT status FROM " + Manual.table + " WHERE id = " + ManualId);
	if(0 < ManualStatus) p.setVar("SYS_MENU_MANUAL_ID", ManualId);
}

p.setVar("WEB_URL", webUrl);
p.setVar("FRONT_URL", siteDomain);
p.setVar("SYS_TITLE", winTitle);
p.setVar("SYS_USERKIND", userKind);
p.setVar("SITE_INFO", siteinfo);
//p.setVar("SITE_CONFIG", siteconfig);
p.setVar("IS_AUTH_CRM", isAuthCrm);
p.setVar("IS_DEV_SERVER", isDevServer);
p.setVar("SYS_LOCALE", sysLocale);
p.setVar("SYS_TODAY", sysToday);
p.setVar("SYS_NOW", sysNow);
//p.setVar("SYS_COMMON_CDN", !isDevServer ? "//cdn.malgnlms.com" : "");
p.setVar("SYS_COMMON_CDN", "");
p.setVar("SYS_VIEWER_VERSION", sysViewerVersion);
p.setVar("SYS_VIEWER_COMMENT", sysViewerComment);

p.setVar("user_master_block", isUserMaster || isMalgnOffice);
p.setVar("malgn_office_block", isMalgnOffice);
p.setVar("super_block", superBlock);
p.setVar("admin_block", adminBlock);
p.setVar("course_manager_block", courseManagerBlock);
p.setVar("dept_manager_block", deptManagerBlock);
p.setVar("SYS_URL", surl);

//boolean isBlindUser = !sysToday.equals(pagreeDate);
//p.setVar("SYS_BLINDUSER", isBlindUser);

//개인정보처리 수정 - 2024.03.25
boolean isBlindUser = !"Y".equals(m.getCookie("PCONFIRM_YN"));
p.setVar("SYS_BLINDUSER", isBlindUser);
p.setVar("PCONFIRM_YN", m.getCookie("PCONFIRM_YN"));
String inquiryPurpose = m.getCookie("INQUIRYPURPOSE");

UserSessionDao UserSession = new UserSessionDao();
UserSession.setSiteId(siteId);
UserSession.setType("sysop");
if(userId != 0 && !"SYSLOGIN".equals(userSessionId) && "N".equals(siteinfo.s("dup_sysop_yn")) && ("".equals(userSessionId) || userSessionId == null || !UserSession.isValid(userSessionId, userId))) {
	if(request.getRequestURI().indexOf("/sysop/main/logout.jsp") == -1) {
		m.jsAlert("세션이 만료되었거나 중복 로그인이 되어 자동으로 로그아웃 됩니다.");
		m.jsReplace("/sysop/main/logout.jsp?mode=session", "top");
		return;
	}
}

InfoLogDao _log = new InfoLogDao(siteId); _log.setItems(userId, "B", surl, userIp);
InfoUserDao _logUser = new InfoUserDao(siteId);

%>
