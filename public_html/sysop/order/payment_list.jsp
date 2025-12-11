<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(60, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int oid = m.ri("oid");
if(oid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
PaymentDao payment = new PaymentDao();
OrderDao order = new OrderDao();

//정보
DataSet info = order.find("id = " + oid);
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//변수
String methods[] = payment.pgMethodsAll.get(siteinfo.s("pg_nm"));

//폼체크
f.addElement("s_method", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(payment.table + " a ");
lm.setFields("a.*");
lm.addWhere("a.oid = " + oid + "");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.paytype", f.get("s_method"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.id, a.respcode, a.respmsg, a.financename, a.cardnum, a.accountnum, a.cardinstallmonth", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("respmsg_conv", m.cutString(list.s("respmsg"), 50));
	list.put("paytype_conv", m.getItem(list.s("paytype"), methods));
	list.put("paydate_conv", m.time("yyyy.MM.dd HH:mm", list.s("paydate")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));

	list.put("SC0010_block", false);
	list.put("SC0030_block", false);
	list.put("SC0040_block", false);
	list.put(list.s("paytype") + "_block", true);
}

//출력
p.setLayout("poplayer".equals(ch) ? "poplayer" : "pop");
p.setBody("order.payment_list");
p.setVar("p_title", "결제내역");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("methods", m.arr2loop(methods));
p.display();

%>