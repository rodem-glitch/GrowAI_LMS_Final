<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근 권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int uid = m.ri("uid");
if(uid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
GroupDao group = new GroupDao();

//정보
DataSet uinfo = user.find("id = " + uid + " AND site_id = " + siteId + " AND status != -1");
if(!uinfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//목록
DataSet list = group.find("id IN ('" + m.replace(group.getUserGroup(uinfo), ",", "','") + "') AND site_id = " + siteId);
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), group.statusList));
}

//출력
p.setLayout("poplayer");
p.setBody("user.user_group");
p.setVar("p_title", "회원그룹 조회");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);

p.display();


%>