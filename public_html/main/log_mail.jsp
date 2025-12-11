<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String logDir = Config.getLogDir();
String today = m.time("yyyyMMdd");
String prefix = "error";
String path = logDir + "/" + prefix + "_" + today + ".log";

File log = new File(logDir);
if(!log.exists()) log.mkdirs();
File logFile = new File(path);
if(!logFile.exists()) {
	//m.errorLog("begin logger");

	FileWriter logger = new FileWriter(logDir + "/logmail.log", false);
	logger.write(today + " 0 0 Log Date : " + m.time("yyyy-MM-dd HH:mm:ss"));
	logger.close();
	return;

} else {
	int lineNo = 0;
	String logmailFile = logDir + "/logmail.log";
	File logmail = new File(logmailFile);
	if(logmail.exists()) {
		String logmailStr = m.readFile(logmailFile);
		String[] arr = logmailStr.split(" ");
		String logDate = arr[0];
		long size = m.parseLong(arr[1]);
		int index = m.parseInt(arr[2]);

		if(today.equals(logDate) && size < logFile.length()) {
			//BufferedReader in = new BufferedReader(new FileReader(logFile));
			FileInputStream fin = new FileInputStream(logFile);
			Reader reader = new InputStreamReader(fin, "UTF-8");
			BufferedReader in = new BufferedReader(reader);

			StringBuffer sb = new StringBuffer();
			String s = "";
			while ((s = in.readLine()) != null) {
				lineNo++;
				if(lineNo > index) sb.append(s + "<br>");
			}
			in.close();
			String msubject = "[LMS호스팅] 로그데이터 - " + m.time("yyyy년 MM월 dd일") + "";
			String mbody = sb.toString();
			if(!"".equals(mbody)) {
				m.mail("hopegiver@malgnsoft.com", msubject, mbody);
				m.mail("chhwi@malgnsoft.com", msubject, mbody);
				m.mail("yhs@malgnsoft.com", msubject, mbody);
			}
			//out.print("DONE!!");
		} else lineNo = index;
	}

	FileWriter logger = new FileWriter(logDir + "/logmail.log", false);
	logger.write(today + " " + logFile.length() + " " + lineNo + " Log Date : " + m.time("yyyy-MM-dd HH:mm:ss"));
	logger.close();
}

%>
