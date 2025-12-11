<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
KollusDao kollus = new KollusDao(siteId);

DataSet channels = kollus.getChannels();
if(null == channels || 1 > channels.size()) {
	m.jsError("유효한 채널이 존재하지 않습니다. 관리자에게 문의바랍니다.");
	return;
}

String basicChannel = "";
while(channels.next()) {
	channels.put("status_conv", "1".equals(channels.s("status")) ? "활성화" : "비활성화");
	if("LMS".equals(channels.s("name").toUpperCase())) basicChannel = channels.s("key");
}

//폼입력
String schannel = !"".equals(m.rs("s_channel")) ? m.rs("s_channel") : basicChannel;

//폼체크
f.addElement("s_channel", schannel, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;

//목록
DataSet totals =  kollus.getContents(schannel, m.rs("s_keyword"), 1, 100000);
int totalNum = totals != null ? totals.size() : 0;

//목록
DataSet list = kollus.getContents(schannel, m.rs("s_keyword"), pg, 10);
int i = 1;
while(list.next()) {
	list.put("use_encryption_conv", "1".equals(list.s("use_encryption")) ? "Y" : "N");
	list.put("encrypt_block", "1".equals(list.s("use_encryption")));
	list.put("__ord", i++);
	list.put("ROW_CLASS", i % 2 == 1 ? "odd" : "even");
	
	String[] duration = m.split(":", list.s("duration"));
	list.put("total_time", m.parseInt(duration[0]) * 60 + m.parseInt(duration[1]));

	DataSet tfinfo = Json.decode(list.s("transcoding_files"));
	while(tfinfo.next()) {
		if(-1 < tfinfo.s("media_profile_group_key").toLowerCase().indexOf("pc")) {
			DataSet minfo = Json.decode(tfinfo.s("media_information"));
			while(minfo.next()) {
				DataSet vinfo = Json.decode(minfo.s("video"));
				if(!vinfo.next()) {
					list.put("content_width", 0);
					list.put("content_height", 0);
				} else {
					String[] size = m.split("x", vinfo.s("video_screen_size"));
					list.put("content_width", size[0]);
					list.put("content_height", size[1]);
				}
			}
		} else if(-1 < tfinfo.s("media_profile_group_key").toLowerCase().indexOf("mobile")) {
			DataSet minfo = Json.decode(tfinfo.s("media_information"));
			while(minfo.next()) {
				DataSet vinfo = Json.decode(minfo.s("video"));
				if(!vinfo.next()) {
					list.put("content_width", 0);
					list.put("content_height", 0);
				} else {
					String[] size = m.split("x", vinfo.s("video_screen_size"));
					list.put("content_width", size[0]);
					list.put("content_height", size[1]);
				}
			}
		}
	}
}

//페이징
Pager pager = new Pager(request);
pager.setTotalNum(totalNum);
pager.setPageNum(pg);
pager.setListNum(10);

//출력
p.setLayout("pop");
p.setBody("kollus.kollus_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("list_total", totalNum);
p.setLoop("list", list);
p.setVar("pagebar", pager.getPager());

p.setLoop("channel_list", channels);
p.display();

%>