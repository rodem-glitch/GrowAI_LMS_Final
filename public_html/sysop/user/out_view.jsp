<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(66, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int uid = m.ri("uid");
if(uid == 0) { m.jsError("기본키는 지정해야 합니다."); return; }

//객체
UserOutDao userOut = new UserOutDao();
UserDao user = new UserDao(isBlindUser);
CategoryDao category = new CategoryDao();

//정보
DataSet info = userOut.query(
	"SELECT a.user_id, a.out_type, a.memo, a.out_date, a.reg_date, a.admin_id, b.id, b.login_id, b.user_nm, b.status, c.user_nm admin_nm, c.login_id admin_login_id "
	+ " FROM " + userOut.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
	+ " LEFT JOIN " + user.table + " c ON a.admin_id = c.id "
	+ " WHERE a.user_id = " + uid + " AND b.site_id = " + siteId + " AND a.status != -1 "
);

String[] confirms = { "1=>탈퇴처리완료", "0=>대기중" };

//포맷팅
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

info.put("out_date_conv", !"".equals(info.s("out_date")) ? m.time("yyyy.MM.dd HH:mm:ss", info.s("out_date")) : "-");
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("admin_nm_conv", !"".equals(info.s("admin_nm")) ? info.s("admin_nm") : "-");
int isConfirm = !"".equals(info.s("out_date")) && -1 == info.i("status") ? 1 : 0;
info.put("confirm_status", m.getItem(""+isConfirm, confirms));
info.put("confirm_block", isConfirm == 1);
info.put("memo", m.htt(info.s("memo")));
String[] cate = info.s("out_type").split("\\,");
user.maskInfo(info);
if(-1 == info.i("status")) info.put("user_nm", "[탈퇴]");

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);


//출력
p.setBody("user.out_view");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setVar(info);
p.setLoop("categories", m.arr2loop(userOut.types));
p.display();

%>