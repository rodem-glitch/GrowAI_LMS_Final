<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
String mode = m.rs("mode");
if(1 > id || "".equals(mode) || 1 > userId) return;

//객체
WishlistDao wishlist = new WishlistDao(siteId);

//출력
if("toggle".equals(mode)) out.print(wishlist.toggle(userId, "webtv", id));
else if("read".equals(mode)) out.print(wishlist.isAdded(userId, "webtv", id) ? 1 : 0);
return;

%>