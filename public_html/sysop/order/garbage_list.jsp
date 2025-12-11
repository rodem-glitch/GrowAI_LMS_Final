<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(140, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderItemDao orderItem = new OrderItemDao();
UserDao user = new UserDao(isBlindUser);
CourseDao course = new CourseDao();
BookDao book = new BookDao();

//변수
String[] statusList = { "10=>장바구니", "20=>결제중", "-99=>주문대기" };
int timeLimit = 2; //시간

//처리-삭제
if("del".equals(m.rs("mode"))) {
    //기본키
    String[] idx = f.getArr("idx");

    DataSet list = orderItem.find("id IN (" + m.join(",", idx) + ")", "*");

    while(list.next()) {
        boolean isOvered = m.diffDate("H", list.s("reg_date"), sysNow) >= timeLimit; //등록일이 2시간이 지났는지
        if(!isOvered || !orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"))) { m.jsAlert("삭제하는 중 오류가 발생했습니다."); return; }
    }

    //이동
    m.jsAlert("삭제가 완료되었습니다.");
    m.jsReplace("garbage_list.jsp?" + m.qs("mode,idx"), "parent");
    return;
}

//폼체크
f.addElement("s_course_id", null, null);
f.addElement("s_product", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? sysExcelCnt : f.getInt("s_listnum", 20));
lm.setTable(
        orderItem.table + " a "
        + " INNER JOIN " + user.table + " u ON a.user_id = u.id"
        + " LEFT JOIN " + course.table + " c ON a.course_id = c.id"
);
lm.setFields(
        "a.* "
        + ", u.login_id, u.user_nm, u.email_yn, u.sms_yn, u.status ustatus"
);
lm.addWhere("a.status IN (10, 20, -99)");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.course_id", f.get("s_course_id"));
lm.addSearch("a.product_type", f.get("s_product"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
    lm.addSearch("a.product_nm,a.user_id,u.user_nm,u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("product_type_conv", m.getItem(list.s("product_type"), orderItem.ptypes));

    list.put("pay_price_conv", m.nf(list.i("pay_price")));
    list.put("reg_date_conv",  m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
    list.put("status_conv", m.getItem(list.s("status"), statusList));

    int tgap = m.diffDate("S", list.s("reg_date"), sysNow);
    if(tgap < 0) tgap = 0;

    list.put("rdays_day", tgap / (24 * 60 * 60));
    list.put("rdays_hour", (tgap / (60 * 60)) % 24);
    list.put("rdays_min", (tgap / 60) % 60);

    list.put("del_block", (tgap / (60 * 60)) >= timeLimit);

    user.maskInfo(list); //마스킹

    if(-2 == list.i("ustatus")){
        list.put("login_id", "탈퇴회원");
    }else if(-1 == list.i("ustatus")){
        list.put("user_nm", "[탈퇴]");
        list.put("login_id", "삭제된회원");
    }

}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setBody("order.garbage_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("time_limit", timeLimit);
p.setLoop("status_list", m.arr2loop(statusList));
//p.setLoop("course_list", course.getList(userId, userKind));
p.setLoop("course_list", course.getCourseList(siteId, userId, userKind));
//p.setLoop("book_list", book.getBookList(siteId));

p.display();

%>