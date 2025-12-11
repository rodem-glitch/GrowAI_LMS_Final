<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(60, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
PaymentDao payment = new PaymentDao();
OrderDao order = new OrderDao();
UserDao user = new UserDao();

//정보
DataSet info = payment.find("id = " + id);
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }
info.put("amount_conv", m.nf(info.i("amount")));
info.put("paytype_conv", m.getItem(info.s("paytype"), order.methods));
info.put("paydate_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("paydate")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
//user.maskInfo(info);

//출력
p.setLayout("poplayer".equals(ch) ? "poplayer" : "pop");
p.setBody("order.payment_view");
p.setVar("p_title", "결제정보");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar(info);

p.display();

%>