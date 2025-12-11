<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ActionLogDao actionLog = new ActionLogDao();

//제한
if(!isUserMaster) { out.print("error|권한이 없습니다."); return; }

//기본키
String prepareYn = f.get("v");
if("".equals(prepareYn)) { out.print("error|기본키는 반드시 지정해야 합니다."); return; }
prepareYn = "Y".equals(prepareYn) ? "Y" : "";

//액션로그-조회
actionLog.item("site_id", siteId);
actionLog.item("user_id", userId);
actionLog.item("module", "site_prepare");
actionLog.item("module_id", siteId);
actionLog.item("action_type", "M");
actionLog.item("action_desc", "마스터ID 공사중 수정");
actionLog.item("before_info", SiteConfig.s("prepare_yn"));
actionLog.item("after_info", prepareYn);
actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
actionLog.item("status", 1);
if(!actionLog.insert()) { out.print("error|조회하는 중 오류가 발생했습니다."); return; }

//처리
SiteConfig.put("prepare_yn", prepareYn);
SiteConfig.remove(siteId + "");

//출력
out.print("success|" + prepareYn);

%>