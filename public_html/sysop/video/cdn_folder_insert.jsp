<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %>
<%@ page import="java.io.UnsupportedEncodingException" %>
<%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
//if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//제한
if("".equals(siteinfo.s("cdn_ftp"))) { m.jsAlert("FTP 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }
String[] arr = m.split("|", siteinfo.s("cdn_ftp"));

//기본키
String dir = m.rs("dir", "/");
if("C".equals(userKind) && !dir.startsWith("/" + userId)) dir = "/" + userId;
//if("".equals(dir)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.CloseLayer();"); return; }


//폼체크
f.addElement("folder_nm", null, "hname:'폴더명', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자 조합으로 입력하세요.'");

//등록
if(m.isPost() && f.validate()) {

	//목록
	FTPClient ftp = new FTPClient();
	try{
		ftp.setControlEncoding("utf-8");
		ftp.connect(arr[0]);
		ftp.enterLocalPassiveMode();

		int loginResult = loginValidate(ftp, m, arr[1], arr[2]);
		if(-1 == loginResult) {
			ftp.disconnect();
			m.jsError("FTP 접속시도가 너무 많습니다. 잠시 후 다시 시도하세요.");
			return;
		} else if (-2 == loginResult) {
			ftp.disconnect();
			m.jsError("FTP 접속정보가 일치하지 않습니다. 관리자에게 문의하세요.");
			return;
		}

		if(!"".equals(dir)) ftp.changeWorkingDirectory(dir);

		boolean ret = ftp.makeDirectory(f.get("folder_nm"));

		if(!ret) {
			ftp.disconnect();
			m.jsError("폴더를 생성하는 중 오류가 발생했습니다.");
			return;
		}

		if(ftp.isConnected()) {
			ftp.logout();
			ftp.disconnect();
		}

	} catch(UnsupportedEncodingException uee) {
		m.log("ftp", uee.toString());
		m.jsError("폴더를 생성하는 중 오류가 발생했습니다. " + uee.toString());
		return;
	} catch(Exception e) {
		m.log("ftp", e.toString());
		m.jsError("폴더를 생성하는 중 오류가 발생했습니다. " + e.toString());
		return;
	}

	//이동
	m.jsReplace("../video/cdn_list.jsp?" + m.qs(), "parent");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("video.cdn_folder_insert");
p.setVar("p_title", "폴더생성");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("dir", dir);

p.display();

%>