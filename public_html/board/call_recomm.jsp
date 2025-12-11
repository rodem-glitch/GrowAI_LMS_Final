<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(0 == id) return;

//객체
PostLogDao postLog = new PostLogDao(siteId);

//등록
if(0 < userId) postLog.log(userId, id, "recomm");

//업데이트
post.updateRecommCount(id);

//출력
out.print(m.nf(post.getOneInt("SELECT recomm_cnt FROM " + post.table + " WHERE id = " + id + " AND site_id = " + siteId + " AND display_yn = 'Y' AND display_yn = 'Y' AND status = 1")));
return;

%>