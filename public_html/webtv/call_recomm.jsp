<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(0 == id) return;

//객체
WebtvDao webtv = new WebtvDao();
WebtvRecommDao webtvRecomm = new WebtvRecommDao(siteId);

//등록
if(0 < userId) webtvRecomm.recomm(userId, id);

//업데이트
webtv.updateRecommCount(id);

//출력
out.print(m.nf(webtv.getOneInt("SELECT recomm_cnt FROM " + webtv.table + " WHERE id = " + id + " AND site_id = " + siteId + " AND status = 1")));
return;

%>