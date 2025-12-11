<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(82, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteDao site = new SiteDao();
UserDeptDao userDept = new UserDeptDao();
UserDao user = new UserDao();
ApiLogDao apiLog = new ApiLogDao();

//정보
DataSet info = site.find("id = " + siteId);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
String[] cdnFtp = m.split("|", info.s("cdn_ftp"));
if(3 > cdnFtp.length) cdnFtp = new String[3];

//폼체크
f.addElement("ovp_vendor", info.s("ovp_vendor"), "hname:'동영상 공급자', required:'Y'");
f.addElement("video_key", info.s("video_key"), "hname:'위캔디오 API키'");
f.addElement("video_pkg", info.s("video_pkg"), "hname:'위캔디오 PKG키'");
f.addElement("access_token", info.s("access_token"), "hname:'콜러스 인증토큰'");
f.addElement("security_key", info.s("security_key"), "hname:'콜러스 보안키'");
f.addElement("custom_key", info.s("custom_key"), "hname:'콜러스 사용자키'");
f.addElement("kollus_channel", info.s("kollus_channel"), "hname:'콜러스 채널키'");
f.addElement("download_yn", info.s("download_yn"), "hname:'영상다운로드 사용여부', required:'Y'");

f.addElement("cdn_ftp_addr", cdnFtp[0], "hname:'CDN FTP 주소'");
f.addElement("cdn_url", info.s("cdn_url"), "hname:'CDN 웹 주소'");
f.addElement("cdn_ftp_id", cdnFtp[1], "hname:'CDN FTP 아이디'");
f.addElement("cdn_ftp_passwd", cdnFtp[2], "hname:'CDN FTP 비밀번호'");

//수정
if(m.isPost() && f.validate()) {

	site.item("ovp_vendor", f.get("ovp_vendor"));
	site.item("video_key", f.get("video_key"));
	site.item("video_pkg", f.get("video_pkg"));
	site.item("access_token", f.get("access_token"));
	site.item("security_key", f.get("security_key"));
	site.item("custom_key", f.get("custom_key"));
	site.item("kollus_channel", f.get("kollus_channel"));
	site.item("download_yn", f.get("download_yn"));

	site.item("cdn_ftp", f.glue("|", "cdn_ftp_addr,cdn_ftp_id,cdn_ftp_passwd"));
	site.item("cdn_url", f.get("cdn_url"));

	if(!site.update("id = " + siteId)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; 	}

	//캐쉬 삭제
	site.remove(info.s("domain"));
	if(!"".equals(info.s("domain2"))) site.remove(info.s("domain2"));

	m.jsAlert("수정되었습니다.");
	m.jsReplace("site_platform_modify.jsp", "parent");
	return;
}

//출력
p.setBody("site.site_platform_modify");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("tab_platform", "current");
p.setLoop("ovp_vendor_list", m.arr2loop(site.ovpVendors));
p.display();

%>