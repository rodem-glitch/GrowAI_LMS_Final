<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String type = m.rs("type", "main");
String tpl = m.rs("tpl", "banner_list");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;
int bid = m.ri("bid");
boolean isSingle = 0 < bid || "Y".equals(m.rs("single"));
if(isSingle) count = 1;

//객체
BannerDao banner = new BannerDao(siteId);

//아이디 지정의 경우 이미지태그 출력
if(bid > 0) {
	banner.printBanner(bid, out);
	return;
}

//목록
DataSet banners = banner.find(
	"status = 1 AND site_id = " + siteId + " AND banner_type = '" + type + "'"
	, "*", "sort ASC", count
);
while(banners.next()) {
	banners.put("banner_text_conv", m.htmlToText(banners.s("banner_text")));
	banners.put("banner_text_htt", m.htt(banners.s("banner_text")));
	banners.put("banner_text_nl2br", m.nl2br(banners.s("banner_text")));
	banners.put("banner_file_url", !"".equals(banners.s("banner_url")) ? banners.s("banner_url") : m.getUploadUrl(banners.s("banner_file")));
	banners.put("link_block", !("".equals(banners.s("link")) || "http://".equals(banners.s("link")) || "https://".equals(banners.s("link"))));
}
if(1 == banners.size()) isSingle = true;

//출력
p.setLayout(null);
p.setBody("main.banner_list");

p.setVar(banners);
p.setLoop("banners", banners);

p.setVar("is_single", isSingle);
p.setVar("type_" + type, true);
p.display();

%>