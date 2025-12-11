<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.net.URL,javax.net.ssl.*" %><%@ include file="init.jsp" %><%

if(true) return;

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
HttpsURLConnection conn = null;
OutputStreamWriter writer = null;
BufferedReader reader = null;

//try {
	URL url = new URL("https://api.ymdr.kr/api/balance");
	//URL url = new URL("https://api.ymdr.kr/api/purchase");
	//URL url = new URL("https://api.ymdr.kr/api/refund");

	conn = (HttpsURLConnection)url.openConnection();
	conn.setRequestProperty("Content-type", "application/json");
	//conn.setRequestProperty("Authorization", "pk_f3b9-c4d81a-24f-3d2cb");
	conn.setRequestProperty("Authorization", "pk_6b78-0b26f4-2fc-6e817");
	conn.setRequestMethod("POST");
	conn.setDoOutput(true);
	HttpsURLConnection.setDefaultHostnameVerifier(new CustomizedHostnameVerifier());

	writer = new OutputStreamWriter(conn.getOutputStream());
	writer.write(params);
	writer.flush();

	reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));

	StringBuffer buffer = new StringBuffer();
	String line;
	while((line = reader.readLine()) != null) buffer.append(line);
	
	Json json = new Json();
	//json.setDebug(out);
	json.setJson(buffer.toString());

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

//} catch(Exception e) {
	//e.printStackTrace();
//} finally {
//	if(writer != null) try { writer.close(); } catch(Exception e) { }
//	if(reader != null) try { reader.close(); } catch(Exception e) { }
//}

%><%!
class CustomizedHostnameVerifier implements HostnameVerifier {
	public boolean verify(String hostname, SSLSession session) {
		return true;
	}
}

%>