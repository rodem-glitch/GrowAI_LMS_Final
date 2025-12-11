<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String ek = f.get("ek");

//제한
if("".equals(ek)) { out.print("기본키는 반드시 지정해야 합니다. 전산담당자에게 문의하세요."); return; }

//객체
UserDao user = new UserDao();
GroupDao group = new GroupDao();
UserDeptDao userDept = new UserDeptDao();
UserLoginDao userLogin = new UserLoginDao();

//변수
String lid, userNm, email, mobile, zipcode, addr, newAddr, addrDtl, deptId, deptCd, gender, birthday, returl, etc1, etc2, etc3;
String now = m.time("yyyyMMddHHmmss");
String log = f.data.toString() + "\n";

if("Y".equals(f.get("encrypted"))) {
    String ssokey = siteinfo.s("sso_key");
    lid = SimpleAES.decrypt(f.get("login_id"), ssokey);
    userNm = SimpleAES.decrypt(f.get("user_nm"), ssokey);
    email = !"".equals(f.get("email")) ? SimpleAES.decrypt(f.get("email"), ssokey) : "";
    mobile = !"".equals(f.get("mobile")) ? SimpleAES.decrypt(f.get("mobile"), ssokey) : "";
    zipcode = !"".equals(f.get("zipcode")) ? SimpleAES.decrypt(f.get("zipcode"), ssokey) : "";
    addr = !"".equals(f.get("addr")) ? SimpleAES.decrypt(f.get("addr"), ssokey) : "";
    newAddr = !"".equals(f.get("new_addr")) ? SimpleAES.decrypt(f.get("new_addr"), ssokey) : "";
    addrDtl = !"".equals(f.get("addr_dtl")) ? SimpleAES.decrypt(f.get("addr_dtl"), ssokey) : "";
    deptId = !"".equals(f.get("dept_id")) ? SimpleAES.decrypt(f.get("dept_id"), ssokey) : "";
    deptCd = !"".equals(f.get("dept_cd")) ? SimpleAES.decrypt(f.get("dept_cd"), ssokey) : "";
    gender = !"".equals(f.get("gender")) ? SimpleAES.decrypt(f.get("gender"), ssokey) : "";
    birthday = !"".equals(f.get("birthday")) ? SimpleAES.decrypt(f.get("birthday"), ssokey) : "";
    returl = !"".equals(f.get("returl")) ? SimpleAES.decrypt(f.get("returl").replaceAll("(\r\n|\r|\n|\n\r)", ""), ssokey) : "";
    etc1 = !"".equals(f.get("etc1")) ? SimpleAES.decrypt(f.get("etc1").replaceAll("(\r\n|\r|\n|\n\r)", ""), ssokey) : "";
    etc2 = !"".equals(f.get("etc2")) ? SimpleAES.decrypt(f.get("etc2").replaceAll("(\r\n|\r|\n|\n\r)", ""), ssokey) : "";
    etc3 = !"".equals(f.get("etc3")) ? SimpleAES.decrypt(f.get("etc3").replaceAll("(\r\n|\r|\n|\n\r)", ""), ssokey) : "";
    log += "{AES} ";
} else {
    lid = f.get("login_id");
    userNm = f.get("user_nm");
    email = f.get("email");
    mobile = f.get("mobile");
    zipcode = f.get("zipcode");
    addr = f.get("addr");
    newAddr = f.get("new_addr");
    addrDtl = f.get("addr_dtl");
    deptId = f.get("dept_id");
    deptCd = f.get("dept_cd");
    gender = f.get("gender");
    birthday = f.get("birthday");
    returl = f.get("returl");
    etc1 = f.get("etc1");
    etc2 = f.get("etc2");
    etc3 = f.get("etc3");

    log += "{NORMAL} ";
}

log += "login_id:" + lid + " / user_nm:" + userNm + " / dept_id:" + deptId + " / dept_cd:" + deptCd + " / etc1:" + etc1;

//포맷팅
birthday = (8 != birthday.length() ? m.time("yyyyMMdd") : m.time("yyyyMMdd", birthday));

//제한
String eKey = m.encrypt(lid + siteinfo.s("sso_key") + m.time("yyyyMMdd"), "SHA-256");
if(!ek.equals(eKey)) {
    m.log("slogin_error", f.data.toString() + " / login_id:" + lid + " / user_nm:" + userNm + " / sso_key:" + siteinfo.s("sso_key") + " / ek:" + ek + " / eKey:" + eKey);
    out.print("올바르지 않은 암호키가 입력돼 로그인이 불가능합니다. 전산담당자에게 문의하세요."); return;
}

int deptNo = (
    "".equals(deptCd)
    ? m.parseInt(deptId)
    : userDept.getOneInt("SELECT id FROM " + userDept.table + " WHERE site_id = " + siteId + " AND CONCAT('|', dept_cd, '|') LIKE '%|" + deptCd + "|%' AND status = 1 ORDER BY sort ASC, id ASC")
);
if(birthday.length() != 8) birthday = "";
if(!"".equals(mobile)) mobile = SimpleAES.encrypt(mobile);
if(!"2".equals(gender)) gender = "1";

log += " / gender_conv:" + gender;

m.log("slogin_test" + siteId, log);

p.setLayout("blank");
p.setBody("member.slogin_test");

p.display();

%>