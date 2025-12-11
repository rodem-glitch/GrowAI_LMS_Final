<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ActionLogDao actionLog = new ActionLogDao();

//제한
if(!isUserMaster) { out.print("error|권한이 없습니다."); return; }

//액션로그-조회
actionLog.item("site_id", siteId);
actionLog.item("user_id", userId);
actionLog.item("module", "site_ftp");
actionLog.item("module_id", siteId);
actionLog.item("action_type", "R");
actionLog.item("action_desc", "마스터ID FTP 정보 조회");
actionLog.item("before_info", "");
actionLog.item("after_info", "");
actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
actionLog.item("status", 1);
if(!actionLog.insert()) { out.print("error|조회하는 중 오류가 발생했습니다."); return; }

//출력
out.print("success|ID : " + siteinfo.s("ftp_id") + " / PW : " + siteinfo.s("ftp_pw"));

%>