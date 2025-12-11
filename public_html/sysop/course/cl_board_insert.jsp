<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int ctid = m.ri("ctid");
if(ctid == 0) { m.jsAlert("해당 카테고리가 없습니다."); return; }

//객체
ClBoardDao board = new ClBoardDao(siteId);
CourseDao course = new CourseDao();

//목록
DataSet list = course.query(
    " SELECT a.*, b.id bid, b.code, b.board_nm"
        + " FROM " + course.table + " a "
        + " LEFT JOIN " + board.table + " b ON b.course_id = a.id AND b.code = 'notice' "
        + " WHERE a.status = 1 AND a.site_id = " + siteId + " AND a.category_id = " + ctid + ""
);

int cnt = 0;
int fail = 0;
//while(list.next()) {
//    if("".equals(list.s("bid"))) {
//        if(!board.insertBoard(list.i("id"))) {
//            fail++;
//        } else {
//            cnt++;
//            out.print(list.i("id") + " 과정의 게시판 생성. <br>");
//        }
//    }
//}

out.print("<br> 총 " + cnt + "개의 과정에 게시판생성");
out.print("<br> 총 " + fail + "개의 과정에 생성실패");
return;
%>