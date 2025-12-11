<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
KollusDao kollus = new KollusDao(siteId);

String channelKey = "";
DataSet channels = kollus.getChannels();
if("user".equals(siteinfo.s("kollus_channel")) && !superBlock) {
	channelKey = kollus.getChannelKey(channels, loginId);
} else {
	channelKey = kollus.getChannelKey(channels, null);
	while(channels.next()) {
		if("비공개".equals(channels.s("name"))) channelKey = channels.s("key");
	}
	channelKey = m.rs("s_channel", channelKey);

	//계정에 사용중인 채널이 여러개 있을 때
	if(channels.size() > 1 && "".equals(channelKey)) {
		if(!"".equals(siteinfo.s("kollus_channel"))) {
			channelKey = siteinfo.s("kollus_channel");
		} else {
			channels.first();
			channels.next();
			channelKey = channels.s("key");
		}
	}
}


if("".equals(channelKey)) {
	//m.jsError("유효한 채널이 존재하지 않습니다. 관리자에게 문의바랍니다.");
	return;
}

//폼입력
String schannel = !"".equals(m.rs("s_channel")) ? m.rs("s_channel") : channelKey;

//폼체크
f.addElement("s_channel", schannel, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;

//목록
DataSet list = kollus.getContents(schannel, m.rs("s_keyword"), pg, 10);
int totalNum = kollus.getTotalNum();
int i = 1;
while(list.next()) {
	list.put("use_encryption_conv", "1".equals(list.s("use_encryption")) ? "Y" : "N");
	list.put("encrypt_block", "1".equals(list.s("use_encryption")));
	list.put("__ord", i++);
	list.put("ROW_CLASS", i % 2 == 1 ? "odd" : "even");
	
	if(!"".equals(list.s("duration")) && -1 < list.s("duration").indexOf(":")) {
		String[] duration = m.split(":", list.s("duration"));

		list.put("total_time", m.parseInt(duration[0]) * 60 + m.parseInt(duration[1]));
	} else {
		list.put("duration", "-");
		list.put("total_time", "0");
	}

	DataSet tfinfo = Json.decode(list.s("transcoding_files"));
	while(tfinfo.next()) {
		if(-1 < tfinfo.s("media_profile_group_key").toLowerCase().indexOf("pc")) {
			DataSet minfo = Json.decode(tfinfo.s("media_information"));
			while(minfo.next()) {
				DataSet vinfo = Json.decode(minfo.s("video"));
				if(vinfo.next() && !"".equals(vinfo.s("video_screen_size")) && -1 < vinfo.s("video_screen_size").indexOf("x")) {
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
p.setBody("video.kollus_select");
p.setVar("p_title", "동영상 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("list_total", totalNum);
p.setLoop("list", list);
p.setVar("pagebar", pager.getPager());
p.setVar("channel_block", !"user".equals(siteinfo.s("kollus_channel")) || superBlock);

p.setLoop("channel_list", channels);
p.display();

%>