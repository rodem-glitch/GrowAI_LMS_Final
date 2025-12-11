<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(76, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//정보
DataSet info = course.find(" id = ? AND site_id = ? AND status != ? ", new Object[] { id, siteId, -1 });
if(!info.next()) { m.jsAlert("해당 과정 정보가 없습니다."); return; }

info.put("postfix_type_conv", m.getItem(info.s("postfix_type"), course.postfixType));
info.put("postfix_ord_conv", m.getItem(info.s("postfix_ord"), course.postfixOrd));

if(m.isPost() && f.validate()) {

    if(!courseUser.setCompleteNo(id, siteId)) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

    m.jsAlert("수료번호 재부여가 완료되었습니다.");
    m.js("parent.location.reload();");
    return;
}

//출력
p.setLayout("poplayer");
p.setBody("complete.pop_reorder_complete_no");
p.setVar(info);
p.setVar("p_title", "수료번호 재부여");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("ord_block", "R".equals(info.s("postfix_type")));

p.display();

%>