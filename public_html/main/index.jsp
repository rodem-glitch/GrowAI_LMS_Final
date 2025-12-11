<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
BannerDao banner = new BannerDao();
MainpageDao mainpage = new MainpageDao();

//목록-메인배너
DataSet banners1 = banner.find("status = 1 AND banner_type = 'main' AND site_id = " + siteId + "", "*", "sort ASC", 4);
while(banners1.next()) {
	banners1.put("banner_file_url", m.getUploadUrl(banners1.s("banner_file")));
}

//목록-우측배너
DataSet banners2 = banner.find("status = 1 AND banner_type = 'right' AND site_id = " + siteId + "", "*", "sort ASC", 4);
while(banners2.next()) {
	banners2.put("banner_file_url", m.getUploadUrl(banners2.s("banner_file")));
}

//목록-상단배너
DataSet banners3 = banner.find("status = 1 AND banner_type = 'top' AND site_id = " + siteId + "", "*", "sort ASC", 4);
while(banners3.next()) {
	banners3.put("banner_file_url", m.getUploadUrl(banners3.s("banner_file")));
}

//목록-메인화면
DataSet mlist = mainpage.find("site_id = " + siteId + " AND display_yn = 'Y' AND status = 1", "*", "sort ASC, id ASC");
while(mlist.next()) {
	if(!"".equals(mlist.s("module_params"))) {
		HashMap<String, Object> sub = Json.toMap(mlist.s("module_params"));
		for(String key : sub.keySet()) {
			mlist.put(m.replace(key, "md_", ""), m.nl2br(sub.get(key).toString()));
		}
	}
}

//출력
p.setLayout(ch);
p.setBody("main.index");
p.setLoop("banners1", banners1);
p.setLoop("banners2", banners2);
p.setLoop("banners3", banners3);
p.setLoop("main_list", mlist);

p.display();

%>