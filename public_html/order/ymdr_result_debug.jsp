<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.net.URL,javax.net.ssl.*" %>
<%@ page import="java.io.IOException" %>
<%@ page import="malgnsoft.json.*" %>
<%@ include file="init.jsp" %><%

//if(true) return;

DataSet plist = new DataSet();
plist.addRow();

//정보-파라미터-balance
plist.put("trackId", "test_" + m.time("yyyyMMddHHmmss"));
plist.put("card", "9993");
plist.put("userId", "test993");
/*
*/
/*
//정보-파라미터-purchase
plist.put("trackId", "test_" + m.time("yyyyMMddHHmmss"));
plist.put("card", "1036759999999993");
plist.put("amount", "2009");
plist.put("ssn", "160301");
plist.put("userId", "test993");
plist.put("telNo", "01045035206");
plist.put("description", "테스트설명");
//정보-파라미터-refund
plist.put("trackId", "test_" + m.time("yyyyMMddHHmmss"));
plist.put("description", "DB등록실패");
plist.put("amount", "10");
plist.put("originTrnNo", "T180312001435");
plist.put("originTrackId", "test_20180312172210");
plist.put("originTrnDate", "20180312");
*/

String params = plist.serialize();
params = "{\"balance\": " + params.substring(1, params.length() - 1) + " }";

//변수
Json json = new Json();

//처리
try {
	Process process = Runtime.getRuntime().exec(new String[] {"/Users/kyounghokim/IdeaProjects/MalgnLMS/bin/ymdr_balance.sh", "pk_6b78-0b26f4-2fc-6e817", params});
	InputStream is = process.getInputStream();
	InputStreamReader isr = new InputStreamReader(is, "UTF-8");
	BufferedReader br = new BufferedReader(isr);
	StringBuffer sb = new StringBuffer();
	String line = null;
	while((line = br.readLine())!= null) {
		sb.append(line);
	}
	br.close();
	isr.close();
	is.close();
	String ret = sb.toString();
	m.p(ret);

/*
	Http http = new Http("https://api.ymdr.kr/api/balance");
	//http.setDebug(out);
	http.setData(params);
	http.setHeader("Content-type", "application/json");
	http.setHeader("Authorization", SiteConfig.s("pay_ymdr_key"));
	http.setHeader("Authorization", "pk_6b78-0b26f4-2fc-6e817");

	String ret = http.send("POST");
	//m.log("ymdr", m.stripTags(ret));
*/

	m.log("ymdr", ret);
	json.setJson(ret);
}
catch(JSONException jsone) {
	m.errorLog("JSONException : " + jsone.getMessage(), jsone);
	m.p(jsone.getMessage());
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}
catch(IOException ioe) {
	m.errorLog("IOException : " + ioe.getMessage(), ioe);
	m.p(ioe.getMessage());
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}
catch(Exception e) {
	m.errorLog("Exception : " + e.getMessage(), e);
	m.p(e.getMessage());
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}

//정보-결과
DataSet result = json.getDataSet("//result");
DataSet balance = json.getDataSet("//balanceResult");
//DataSet purchase = json.getDataSet("//purchaseResult");
//DataSet settle = json.getDataSet("//purchaseResult/settleResult");
//DataSet purchase = json.getDataSet("//refundResult");
//DataSet settle = json.getDataSet("//refundResult/settleResult");
m.p(result);
m.p(balance);
//m.p(purchase);
//m.p(settle);


%>