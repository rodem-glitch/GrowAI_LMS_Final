<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(66, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int uid = m.ri("uid");
if(uid == 0) { m.jsError("기본키는 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserOutDao userOut = new UserOutDao();

//정보
DataSet info = userOut.find("user_id = ? AND status != -1", new Object[] {uid});
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//수정-회원
user.item("status", 1);
if(!user.update("id = " + uid)) { m.jsError("복구하는 중 오류가 발생했습니다."); return; }

//삭제-회원탈퇴
userOut.execute("DELETE FROM " + userOut.table + " WHERE user_id = " + uid);

m.jsReplace("out_list.jsp?" + m.qs("uid"));


%>