<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern,java.util.regex.Matcher" %><%@ include file="/init.jsp" %><%!

public String exec(String cmd) {
	try{
		Process p = Runtime.getRuntime().exec(cmd);
		BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
		String line = null;
		String ret = "";
		while((line = br.readLine()) != null){
			ret += line;
		}
		return ret;
	} catch(RuntimeException re){
		return re.toString();
	} catch(Exception e){
		return e.toString();
	}
}

%><%

//기본키
String ek = m.rs("ek");
String mode = m.rs("mode", "create");
String ftpId = m.rs("ftp_id");
String ftpPw = m.rs("ftp_pw");

//접근권한
if(!m.encrypt("SITE_SETUP_" + ftpId + "_SH72F" + m.time("yyyyMMdd")).equals(ek)) {
	out.print("올바른 접근이 아닙니다.");
	return;
}

if("".equals(ftpId) || "".equals(ftpPw)) {
	out.print("FTP 아이디, 암호가 필요합니다.");	
	return;
}

if("create".equals(mode)) {

	File dir = new File("/home/" + ftpId);
	if(dir.exists()) {
		out.print("이미 등록된 계정입니다.");
		return;
	}

	try {
		String cmd = "/root/setup.sh " + ftpId;
		exec(cmd);
		if(!dir.exists()) {
			out.print("계정성생시 오류가 발생했습니다.");
			return;
		}
	} catch(RuntimeException re) {
		out.print("계정생성시 오류가 발생했습니다. " + re.toString());
		return;
	} catch(Exception e) {
		out.print("계정생성시 오류가 발생했습니다. " + e.toString());
		return;
	}

}

if("create".equals(mode) || "banner".equals(mode)) {

	//배너복사
	BannerDao banner = new BannerDao();
	Pattern pattern = Pattern.compile("^(?:.*\\/|)([a-zA-Z0-9]+\\.[a-zA-Z]+)$");
	DataSet binfo = banner.find("site_id = " + siteId + " AND status = 1", "*", "sort ASC", 1);
	if(binfo.next()) {
		Matcher matcher = pattern.matcher(m.getUploadUrl(binfo.s("banner_file")));
		if(matcher.find() && matcher.group(1) != null) {
			try {
				String cmd = "/root/setup_banner.sh " + ftpId + " " + matcher.group(1);
				exec(cmd);
			} catch(RuntimeException re) {
				out.print("배너복사시 오류가 발생했습니다. " + re.toString());
				//return;
			} catch(Exception e) {
				out.print("배너복사시 오류가 발생했습니다. " + e.toString());
				//return;
			}
		}
	}

}

if("create".equals(mode) || "passwd".equals(mode)) {
	try {
		String cmd = "/root/chpasswd.sh " + ftpId + " " + ftpPw;
		exec(cmd);
	} catch(RuntimeException re) {
		out.print("비밀번호 변경시 오류가 발생했습니다. " + re.toString());
		return;
	}catch(Exception e) {
		out.print("비밀번호 변경시 오류가 발생했습니다. " + e.toString());
		return;
	}
}

out.print("success");

%>