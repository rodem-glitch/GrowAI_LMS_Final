

String params = "{\"grant_type\": \"authorization_code\", \"client_id\": \"131\", \"client_secret\": \"EZGF1TBMGpt8PXhpKrR2OaXFckJmfBoTV4tHE6Jl\", \"redirect_uri\": \""
+ m.urlencode("https://lms.malgn.co.kr/sysop/kollus/live_list.jsp") + "\", \"code\": \"" + code + "\", \"state\": \"" + state + "\" }";

//변수
HttpsURLConnection conn = null;
OutputStreamWriter writer = null;
BufferedReader reader = null;

//try {
URL url2 = new URL(url);
conn = (HttpsURLConnection)url2.openConnection();
conn.setRequestProperty("Content-type", "application/json");
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

m.p(buffer.toString());

Json json = new Json();
//json.setDebug(out);
json.setJson(buffer.toString());

//DataSet result = json.getDataSet("//result");
//DataSet balance = json.getDataSet("//balanceResult");
//DataSet purchase = json.getDataSet("//purchaseResult");
//DataSet settle = json.getDataSet("//purchaseResult/settleResult");
//DataSet purchase = json.getDataSet("//refundResult");
//DataSet settle = json.getDataSet("//refundResult/settleResult");
//m.p(result);
//m.p(balance);
//m.p(purchase);
//m.p(settle);
