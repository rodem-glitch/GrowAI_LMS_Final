<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!"Y".equals(SiteConfig.s("doczoom_yn"))) { m.jsErrClose("문서(닥줌) 서비스를 이용하고 있지 않습니다."); return; }

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
DoczoomDao doczoom = new DoczoomDao();

//폼체크
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;

//컨텐츠 목록을 가져올 때 지정할 조건값들. Integer 변수에 null을 지정하면 해당 조건은 무시됩니다.
String userID = "malgn_" + siteinfo.s("ftp_id");
String title = m.rs("s_keyword", null);
String tag = null;
String categoryID = null;

int totalNum = doczoom.getContentCount(userID, title, tag, categoryID);
int pageSize = 10;  //한 페이지당 항목 개수

DataSet list = doczoom.getPaginatedContentInfoListWithFilters(pageSize, pg, 1, 1, userID, title, tag, categoryID);
while(list.next()) {
	long t = Long.parseLong(list.s("RegistrationDate").replace("/Date(", "").replace(")/", ""));
	list.put("RegistrationDate", m.time("yyyy.MM.dd", new Date(t)));
	list.put("DocZoomSize", m.getFileSize(list.i("DocZoomSize")));
}
//페이징
Pager pager = new Pager(request);
pager.setTotalNum(totalNum);
pager.setPageNum(pg);

//출력
p.setLayout("pop");
p.setBody("video.doczoom_select");
p.setVar("p_title", "문서 콘텐츠 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("list_total", totalNum);
p.setVar("pagebar", pager.getPager());
p.setLoop("list", list);
p.display();

%>