<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
UserDao user = new UserDao();
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();

//폼체크
f.addElement("group_id", null, "hname:'회원그룹', required:'Y'");

//제한
DataSet info = coupon.find("site_id = " + siteId + " AND id = " + id);
if(!info.next()) { m.jsError("해당 쿠폰정보가 없습니다."); m.js("parent.CloseLayer();"); }

//목록
DataSet groups = group.find("status = 1 AND site_id = " + siteId + "", "*", "group_nm ASC");
if(!groups.next()) { m.jsAlert("해당 그룹이 없습니다."); m.js("parent.CloseLayer();"); }

if(m.isPost() && f.validate()) {

    int failCnt = 0;
    int successCnt = 0;
    int gid = f.getInt("group_id");

    String now = m.time("yyyyMMddHHmmss");

    DataSet ginfo = group.find("id = '" + gid + "' AND site_id = " + siteId + "");
    if(!ginfo.next()) { m.jsAlert("해당 그룹이 없습니다."); return; }

    String depts = !"".equals(ginfo.s("depts")) ? m.replace(ginfo.s("depts").substring(1, ginfo.s("depts").length()-1), "|", ",") : "";
    DataSet list = user.query(
        "SELECT id"
            + " FROM " + user.table + " a "
            + " WHERE a.site_id = " + siteId + " AND"
            + (!"".equals(depts) ? " a.status = 1 AND ( a.dept_id IN (" + depts + ") OR " : " ( a.status = 1 AND ")
            + " EXISTS ( "
            + " SELECT 1 FROM " + groupUser.table + " "
            + " WHERE group_id = " + gid + " AND add_type = 'A' "
            + " AND user_id = a.id "
            + " ) ) AND NOT EXISTS ( "
            + " SELECT 1 FROM " + groupUser.table + " "
            + " WHERE group_id = " + gid + " AND add_type = 'D' "
            + " AND user_id = a.id "
            + " ) "
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
p.setBody("coupon.pop_group_insert");
p.setVar("p_title", "회원그룹 일괄발행");
p.setLoop("groups", groups);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.display();

%>