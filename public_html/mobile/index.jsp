<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
BannerDao banner = new BannerDao();
MainpageDao mainpage = new MainpageDao();

//목록-메인배너
DataSet banners = banner.find("status = 1 AND banner_type = 'mobile' AND site_id = " + siteId + "", "*", "sort ASC");
while(banners.next()) {
	banners.put("banner_file_url", m.getUploadUrl(banners.s("banner_file")));
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
if(userB2BBlock) {
	p.setBody("mobile.index_b2b");
} else if(new File(tplRoot + "/mobile/index_skin" + siteinfo.s("skin_cd") + ".html").exists()) {
	p.setBody("mobile.index_skin" + siteinfo.s("skin_cd"));
} else {
	p.setBody("mobile.index");
}
p.setLoop("banners", banners);
p.setLoop("main_list", mlist);

p.setVar("main_block", true);
p.display();

%>