<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String url = m.rs("url");
if("".equals(url)) return;

//출력
try{
    Process proc = Runtime.getRuntime().exec("sh /root/script/videoinfo.sh " + url);
    BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()));
    String line = br.readLine();
    br.close();

    String[] arr = line.split("\t");
    out.print(arr[0]);
}catch(NullPointerException npe) {
    m.errorLog("NullPointerException : " + npe.getMessage(), npe);
}catch(RuntimeException re) {
    m.errorLog("RuntimeException : " + re.getMessage(), re);
}catch(Exception e) {
    m.errorLog("Exception : " + e.getMessage(), e);
}

%>