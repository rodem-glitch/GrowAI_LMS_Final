<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ActionLogDao actionLog = new ActionLogDao();
SiteDao site = new SiteDao();

//제한
if(!isUserMaster) { out.print("error|권한이 없습니다."); return; }

//기본키
int sid = m.ri("sid");
if(1 > sid) { out.print("error|기본키는 반드시 지정해야 합니다."); return; }

//액션로그-조회
actionLog.item("site_id", siteId);
actionLog.item("user_id", userId);
actionLog.item("module", "site_master_slogin");
actionLog.item("module_id", sid);
actionLog.item("action_type", "R");
actionLog.item("action_desc", "마스터ID 관리자 로그인 정보 조회");
actionLog.item("before_info", siteId);
actionLog.item("after_info", sid);
actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
actionLog.item("status", 1);
if(!actionLog.insert()) { out.print("error|조회하는 중 오류가 발생했습니다."); return; }

//정보
DataSet info = site.find("id = ? AND sysop_status = 1 AND status != -1", new Integer[] {sid});
if(!info.next()) { out.print("error|해당 정보가 없습니다."); return; }

//출력
out.print("success|uid=" + info.s("super_id") + "&ek=" + m.md5("SEK" + info.i("super_id") + sysToday));
%>