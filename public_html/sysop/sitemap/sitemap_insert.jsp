<%@ page import="java.io.IOException" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao(siteId);
BannerDao banner = new BannerDao();

//코드체크
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < sitemap.findCount("code = '" + value + "' AND site_id = " + siteId + " AND status != -1")) {
		out.print("<span class='bad'>사용 중인 코드입니다. 다시 입력해 주세요.</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 코드입니다.</span>");
	}
	return;
}

String parentCd = !"".equals(f.get("parent_cd")) ? f.get("parent_cd") : m.rs("parent_cd");

//상위정보
DataSet pinfo = sitemap.find("site_id = " + siteId + " AND code = '" + parentCd + "' AND status != -1");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	sitemap.findCount("site_id = " + siteId + " AND status != -1 AND parent_cd = '" + pinfo.s("code") + "' AND depth = " + (pinfo.i("depth") + 1))
	: sitemap.findCount("site_id = " + siteId + " AND status != -1 AND depth = 1");

DataSet sortList = new DataSet();
for(int i = 0; i <= maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i + 1);
}

//폼체크
f.addElement("menu_nm", null, "hname:'메뉴명', required:'Y'");
f.addElement("code", null, "hname:'메뉴코드', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.'");
//f.addElement("module", null, "hname:'링크모듈종류'");
//f.addElement("module_id", null, "hname:'링크모듈아이디'");
f.addElement("link", null, "hname:'링크주소'");
f.addElement("target", "_self", "hname:'타겟', required:'Y'");
f.addElement("layout", null, "hname:'레이아웃'");
f.addElement("sort", (maxSort + 1), "hname:'순서', required:'Y', option:'number'");
f.addElement("display_type", "A", "hname:'노출유형', required:'Y'");
f.addElement("display_yn", "Y", "hname:'노출여부', required:'Y'");
f.addElement("status", "1", "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//제한-메뉴코드
	if(!f.get("code").matches("^[a-zA-Z]{1}[a-zA-Z0-9_\\-]{1,19}$")) {
		m.jsError("구분은 영문으로 시작하는 2-20자로 영문, 숫자, 언더바(_), 하이픈(-) 조합으로 입력하세요.");
		return;
	}

	//제한-중복여부
	if(0 < sitemap.findCount("code = ? AND site_id = " + siteId + " AND status != -1", new String[] { f.get("code") })) {
		m.jsError("이미 사용 중인 코드입니다. 다시 입력해 주세요.");
		return;
	}

	//레이아웃등록
	if(0 == pinfo.i("depth")) {
		boolean writeBlock = false;

		String layoutPath = docRoot + "/html/layout/layout_" + f.get("code") + ".html";
		String templatePath = docRoot + "/html/layout/template_layout.html";
		File layoutFile = new File(layoutPath);
		File templateFile = new File(templatePath);
		if(!layoutFile.exists()) {
			//파일없음
			writeBlock = true;
		} else {
			//파일있음
			FileInputStream fis = new FileInputStream(layoutFile);
			Reader reader = new InputStreamReader(fis, "UTF-8");
			BufferedReader br = new BufferedReader(reader);
			if("<!--#TPL-->".equals(br.readLine())) writeBlock = true;
			br.close();
		}

		//처리-레이아웃파일
		if(writeBlock) {
			//복사-템플릿
			if(!templateFile.exists()) {
				if(!copyFile(Config.getTplRoot() + "/layout/template_layout.html", templatePath)) {
					m.jsError("템플릿파일을 복사하는 중 오류가 발생했습니다.");	
				}
			}

			//읽기-템플릿
			String line = "";
			StringBuffer sb = new StringBuffer();
			FileInputStream fis = new FileInputStream(templateFile);
			Reader reader = new InputStreamReader(fis, "UTF-8");
			BufferedReader br = new BufferedReader(reader);
			while((line = br.readLine()) != null) {
				sb.append(line + "\n");
			}

			//쓰기-레이아웃파일
			FileWriter fw = new FileWriter(layoutPath, false);
			fw.write(m.replace(m.replace(sb.toString(), "{code}", f.get("code")), "{menu_nm}", f.get("menu_nm")));
			fw.close();
		}
		
		//처리-배너
		DataSet binfo = banner.find("banner_type = 'sub_" + f.get("code") + "' AND site_id = " + siteId + " AND status != -1");
		if(!binfo.next()) {
			//파일복사
			if(!copyFile(Config.getTplRoot() + "/images/sub/sub1.jpg", m.getUploadPath("subvisual_" + sysNow + ".jpg"))) {
				m.jsError("서브비주얼 파일을 복사하는 중 오류가 발생했습니다.");	
			}

			//등록
			banner.item("site_id", siteId);
			banner.item("banner_type", "sub_" + f.get("code"));
			banner.item("banner_nm", "서브비주얼 - " + f.get("menu_nm"));
			banner.item("banner_text", ""); //f.get("menu_nm")
			banner.item("link", "");
			banner.item("target", "_self");
			banner.item("width", 0);
			banner.item("height", 0);
			banner.item("sort", 1);
			banner.item("banner_file", "subvisual_" + sysNow + ".jpg");
			banner.item("reg_date", m.time("yyyyMMddHHmmss"));
			banner.item("status", f.getInt("status"));

			if(!banner.insert()) {
				m.jsAlert("서브비주얼을 등록하는 중 오류가 발생했습니다.");
				return;
			}
		}
		if(1 > binfo.i("status")) {
			//수정
			banner.item("status", 1);
			if(!banner.update("id = " + binfo.i("id") + " AND site_id = " + siteId)) { m.jsError("서브비주얼을 수정하는 중 오류가 발생했습니다."); return; }
		}
	}

	int newId = sitemap.getSequence();
	sitemap.item("id", newId);
	sitemap.item("site_id", siteId);
	sitemap.item("code", f.get("code"));
	sitemap.item("parent_cd", "".equals(parentCd) ? "" : parentCd);
	sitemap.item("menu_nm", f.get("menu_nm"));
	//sitemap.item("layout", f.get("layout"));
	sitemap.item("target", f.get("target"));
	sitemap.item("link", f.get("link"));
	sitemap.item("depth", pinfo.i("depth") + 1);
	sitemap.item("sort", f.getInt("sort"));
	sitemap.item("display_type", f.get("display_type", "A"));
	sitemap.item("display_yn", f.get("display_yn", "N"));
	sitemap.item("reg_date", m.time("yyyyMMddHHmmss"));
	sitemap.item("status", f.getInt("status"));

	if(!sitemap.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//정렬
	sitemap.sortDepth(f.get("code"), f.getInt("sort"), maxSort + 1);

	//페이지 파일 생성
	//sitemap.createFile(f.get("link"), ""+newId);

	out.print("<script>parent.left.location.href='sitemap_tree.jsp?" + m.qs("code,parent_cd") + "&scode=" + parentCd + "';</script>");
	m.jsReplace("sitemap_insert.jsp?" + m.qs("code,parent_cd") + "&parent_cd=" + parentCd);
	return;
}

//상위코드 명
String pnames = "";
if(!"".equals(parentCd)) {
	DataSet temp = sitemap.getList();
	pnames = sitemap.getTreeNames(parentCd);
}

//페이지 출력
p.setLayout("blank");
p.setBody("sitemap.sitemap_insert");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("parent_name", "".equals(pnames) ? "-" : pnames);
p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);

p.setLoop("display_types", m.arr2loop(sitemap.displayTypes));
p.setLoop("display_yn", m.arr2loop(sitemap.displayYn));
p.setLoop("status_list", m.arr2loop(sitemap.statusList));

p.display();

%><%!
public boolean copyFile(String inPath, String outPath) throws Exception {
	//변수
	File inFile = new File(inPath);
	File outFile = new File(outPath);
	InputStream inStream = null;
	OutputStream outStream = null;
	byte[] buffer = new byte[1024];
	int length = 0;
	boolean result = true;

	try {
		//변수
		inStream = new FileInputStream(inFile); //원본
		outStream = new FileOutputStream(outFile); //복사

		//복사
		while((length = inStream.read(buffer)) > 0) {
			outStream.write(buffer, 0, length);
		}
	} catch(IOException ioe) {
		//e.printStackTrace();
		result = false;
	} catch(Exception e) {
		//e.printStackTrace();
		result = false;
	} finally {
		inStream.close();
		outStream.close();
	}

	return result;
}
%>