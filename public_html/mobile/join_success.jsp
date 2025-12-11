<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//PC통합
String qs = m.qs("");
if(!"".equals(qs)) qs = "?" + qs;
response.sendRedirect("/member/join_success.jsp" + qs);
if(true) return;

//기본키
String ek = m.rs("ek");
String key = m.rs("k");
String uek = m.rs("uek");
String ukey = m.rs("uk");
if("".equals(ek) || "".equals(key) || "".equals(uek) || "".equals(ukey)) { m.jsError(_message.get("alert.common.required_key")); return; }

//제한
if(!ek.equals(m.encrypt(key + "_AGREE")) || !uek.equals(m.encrypt(ukey + "_NEWUSERID"))) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }

//객체
UserDao user = new UserDao();

//정보-회원
DataSet uinfo = user.find("id = " + ukey + " AND site_id = " + siteId + " AND status != -1");
if(!uinfo.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
uinfo.put("sms_yn_conv", m.getItem(uinfo.s("sms_yn"), user.receiveYn));
uinfo.put("email_yn_conv", m.getItem(uinfo.s("email_yn"), user.receiveYn));
uinfo.put("reg_date_conv", m.time(_message.get("format.datetime.local"), uinfo.s("reg_date")));

//출력
p.setLayout("mobile");
p.setBody("mobile.join_success");

p.setVar(uinfo);
p.display();

%>