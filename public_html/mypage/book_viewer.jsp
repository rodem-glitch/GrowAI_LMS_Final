<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int buid = m.ri("buid");
int bid = m.ri("bid");
if(buid == 0 && bid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookUserDao bookUser = new BookUserDao();
BookDao book = new BookDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);
FreepassUserDao fpuser = new FreepassUserDao();

//권한여부 체크
if(fpuser.findCount(
	"user_id = " + userId + " AND status = 1 AND end_date >= '" + m.time("yyyyMMdd") + "'"
) == 0) {
	if(bookUser.findCount(
		"book_id = " + bid + " AND user_id = " + userId + " AND status IN (0, 1, 3) "
		+ " AND (permanent_yn = 'Y' OR end_date >= '" + m.time("yyyyMMdd") + "') "
	) == 0) {
		m.jsErrClose("정기구독을 신청하시거나 구매를 한 후에 책을 보실 수 있습니다.");
		return;
	}
}

DataSet info = book.query(
	"SELECT a.lesson_id, b.lesson_type, b.start_url"
	+ " FROM " + book.table + " a"
	+ " INNER JOIN " + lesson.table + " b ON b.id = a.lesson_id"
	+ " WHERE a.id = " + bid + " AND a.status = 1"
);

if(!info.next()) { m.jsErrClose("해당 책 정보를 찾을 수 없습니다."); return; }
int lid = info.i("lesson_id");

//동영상경로보안
String ltype = info.s("lesson_type");
if("01".equals(ltype) || "03".equals(ltype)) {
	info.put("start_url_conv", "/player/jwplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd")));
} else if("05".equals(ltype)) {
	info.put("start_url_conv", kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_" + loginId));
} else if("02".equals(ltype) || "04".equals(ltype)) {
	info.put("start_url_conv", info.s("start_url"));
} else if("06".equals(info.s("lesson_type"))) {
	m.jsErrClose("펍트리 서비스가 종료되었습니다. 관리자에게 문의바랍니다.");
	return;
} else {
	m.jsErrClose("전자책 콘텐츠를 찾을 수 없습니다.");
	return;
}

p.setLayout(null);
p.setBody("mypage.book_viewer");
p.setVar(info);
p.display();

%>