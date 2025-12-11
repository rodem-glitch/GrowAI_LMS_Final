<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;

//객체
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();

//목록
//user.setDebug(out);
DataSet list = user.query(
	" SELECT t.* "
	+ " FROM " + tutor.table + " t "
	+ " INNER JOIN " + user.table + " a ON a.id = t.user_id"
	+ " WHERE t.site_id = " + siteId + " AND t.status = 1 AND a.tutor_yn = 'Y' AND a.display_yn = 'Y' AND a.status = 1 ORDER BY t.sort, a.user_nm"
	, count
);
while(list.next()) {
	list.put("tutor_nm_conv", m.cutString(list.s("tutor_nm"), 18));
	if(!"".equals(list.s("tutor_file"))) {
		list.put("tutor_file_url", m.getUploadUrl(list.s("tutor_file")));
	} else {
		list.put("tutor_file_url", "/html/images/common/noimage_tutor.jpg");
	}
}

//출력
p.setLayout(null);
p.setBody("inc.tutor_list");
p.setLoop("list", list);
p.display();

%>