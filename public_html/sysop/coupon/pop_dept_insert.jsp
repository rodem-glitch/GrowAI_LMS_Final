<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("dept_id", null, "hname:'회원소속', required:'Y'");
f.addElement("child_yn", null, "hname:'하위포함'");

//제한
DataSet info = coupon.find("site_id = " + siteId + " AND id = " + id);
if(!info.next()) { m.jsError("해당 쿠폰정보가 없습니다."); m.js("parent.CloseLayer();"); }

//목록
DataSet depts = userDept.getAllList(siteId);
if(!depts.next()) { m.jsAlert("해당 소속이 없습니다."); m.js("parent.CloseLayer();"); }

if(m.isPost() && f.validate()) {

    int failCnt = 0;
    int successCnt = 0;
    int did = f.getInt("dept_id");

    String now = m.time("yyyyMMddHHmmss");

    DataSet dinfo = userDept.find("id = '" + did + "' AND site_id = " + siteId + " AND status = 1 ");
    if(!dinfo.next()) { m.jsAlert("해당 소속이 없습니다."); return; }

    DataSet list = user.query(
        "SELECT a.id"
        + " FROM " + user.table + " a "
        + " INNER JOIN " + userDept.table + " d ON a.dept_id = d.id AND d.site_id = " + siteId + " AND d.status = 1 "
        + " WHERE a.site_id = " + siteId + " AND a.status = 1 "
        + ("Y".equals(f.get("child_yn")) ? " AND a.dept_id IN (" + userDept.getSubIdx(siteId, did) + ")" : " AND a.dept_id = " + did + "")
    );

    while(list.next()) {
        couponUser.item("site_id", siteId);
        couponUser.item("coupon_no", coupon.getCouponNo());
        couponUser.item("coupon_id", id);
        couponUser.item("user_id", list.i("id"));
        couponUser.item("use_yn", "N");
        couponUser.item("use_date", "");
        couponUser.item("reg_date", now);

        if(!couponUser.insert()) {
            couponUser.item("coupon_no", coupon.getCouponNo());
            if(!couponUser.insert()) { failCnt++; }
        }
        else successCnt++;
    }
    if(failCnt > 0) m.jsAlert("쿠폰 발행을 " + failCnt + "건 실패하였습니다.");
    coupon.updateCouponCnt(id);

    m.jsAlert(successCnt + "장의 쿠폰을 추가 발행하였습니다.");
    m.js("parent.location.href = parent.location.href;");
    return;
}

//출력
p.setLayout("poplayer");
p.setBody("coupon.pop_dept_insert");
p.setVar("p_title", "회원소속 일괄발행");
p.setLoop("depts", depts);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.display();

%>