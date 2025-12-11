<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

VimeoDao vimeo = new VimeoDao("ebaff89ff9c3648b83acb3d4cd0f6e84");
DataSet list = vimeo.getVideos(f.get("s_keyword"));

//m.p(list);
while(list.next()) {
	int seconds = list.i("duration");
    int minutes = (seconds % 3600) / 60;
    seconds = seconds % 60;

	list.put("duration_conv", "" + (minutes < 10 ? "0" + minutes : minutes) + ":" + (seconds < 10 ? "0" + seconds : seconds));
	list.put("reg_date", list.s("created_time").substring(0, 10));
}

p.setLayout("sysop");
p.setBody("video.vimeo_list");
p.setVar("p_title", "비메오 동영상 목록");
p.setLoop("list", list);
p.display();

%>