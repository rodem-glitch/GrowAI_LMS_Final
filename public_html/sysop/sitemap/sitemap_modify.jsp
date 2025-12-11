<%@ page contentType="text/html; charset=utf-8" %><%@page import="java.io.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String code = m.rs("code");
if("".equals(code)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao(siteId);
BannerDao banner = new BannerDao();

//정보
DataSet info = sitemap.find("code = '" + code + "' " + (!"Y".equals(SiteConfig.s("join_b2b_yn")) ? " AND code NOT LIKE 'b2b%'" : "") + " AND status != -1 AND site_id = " + siteId);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//변수
boolean changed = m.isPost() && !"".equals(f.get("parent_cd")) && !info.s("parent_cd").equals(f.get("parent_cd"));
String parentCd = changed ? f.get("parent_cd") : info.s("parent_cd");

//정보-상위
DataSet pinfo = sitemap.find("code = '" + parentCd + "' AND status != -1 AND site_id = " + siteId + "");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	sitemap.findCount("site_id = " + siteId + " AND status != -1 AND parent_cd = '" + pinfo.s("code") + "' AND depth = " + (pinfo.i("depth") + 1))
	: sitemap.findCount("site_id = " + siteId + " AND status != -1 AND depth = 1");

//순서
DataSet sortList = new DataSet();
for(int i = 0; i < maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//폼체크
if(1 == siteId) f.addElement("default_yn", info.s("default_yn"), "hname:'기본메뉴여부', required:'Y'");
f.addElement("menu_nm", info.s("menu_nm"), "hname:'메뉴명', required:'Y'");
//f.addElement("layout", info.s("layout"), "hname:'레이아웃'");
//f.addElement("module", info.s("module"), "hname:'링크모듈종류'");
//f.addElement("module_id", info.s("module_id"), "hname:'링크모듈아이디'");
//f.addElement("module_nm", sitemap.getModuleNm(info.s("module"), info.i("module_id")), "hname:'링크모듈명'");
f.addElement("link", info.s("link"), "hname:'링크주소'");
f.addElement("target", info.s("target"), "hname:'타겟'");
f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");
f.addElement("display_type", info.s("display_type"), "hname:'노출유형', required:'Y'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	//레이아웃확인
	//if(0 == pinfo.i("depth") && !info.s("menu_nm").equals(f.get("menu_nm"))) {
	if(0 == pinfo.i("depth")) {
		boolean writeBlock = false;

		String layoutPath = docRoot + "/html/layout/layout_" + info.s("code") + ".html";
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
			fw.write(m.replace(m.replace(sb.toString(), "{code}", info.s("code")), "{menu_nm}", f.get("menu_nm")));
			fw.close();
		}
		
		//처리-배너
		DataSet binfo = banner.find("banner_type = 'sub_" + info.s("code") + "' AND site_id = " + siteId + " AND status != -1");
		if(!binfo.next()) {
			//파일복사
			if(!copyFile(Config.getTplRoot() + "/images/sub/sub1.jpg", m.getUploadPath("subvisual_" + sysNow + ".jpg"))) {
				m.jsError("서브비주얼 파일을 복사하는 중 오류가 발생했습니다.");	
			}

			//등록
			banner.item("site_id", siteId);
			banner.item("banner_type", "sub_" + info.s("code"));
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

		//수정
		banner.item("banner_nm", "서브비주얼 - " + f.get("menu_nm"));
		//banner.item("banner_text", f.get("menu_nm"));
		if(1 > binfo.i("status")) banner.item("status", 1);
		if(!banner.update("id = " + binfo.i("id") + " AND site_id = " + siteId)) { m.jsError("서브비주얼을 수정하는 중 오류가 발생했습니다."); return; }
	}

	//sitemap.item("module", f.get("module"));
	//sitemap.item("module_id", f.getInt("module_id"));
	if(1 == siteId) sitemap.item("default_yn", f.get("default_yn"));
	sitemap.item("parent_cd", parentCd);
	sitemap.item("menu_nm", f.get("menu_nm"));
	//sitemap.item("layout", f.get("layout"));
	sitemap.item("target", f.get("target"));
	sitemap.item("link", f.get("link"));
	sitemap.item("depth", pinfo.i("depth") + 1);
	sitemap.item("sort", f.getInt("sort"));
	sitemap.item("display_type", f.get("display_type", "A"));
	sitemap.item("display_yn", f.get("display_yn", "N"));
	sitemap.item("status", f.getInt("status"));

	if(!sitemap.update("code = '" + code + "' AND site_id = " + siteId)) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	if(changed) { // 부모가 변경 되었을 경우
		/*
		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			sitemap.execute("UPDATE " + sitemap.table + " SET depth = depth + (" + cdepth + ") WHERE code IN (" + sitemap.getSubCodes(code) + ") AND site_id = " + siteId);
		}
		*/
		// 이동된 위치를 다시 정렬한다.
		sitemap.sortDepth(code, f.getInt("sort"), maxSort + 1);
		// 이동전 위치를 정렬한다.
		sitemap.autoSort(info.i("depth"), info.s("parent_cd"));
	} else {
		// 해당 위치만 정렬한다.
		sitemap.sortDepth(code, f.getInt("sort"), info.i("sort"));
	}

	//페이지 파일 생성
	//sitemap.createFile(f.get("link"), ""+id);

	m.js("parent.left.location.href='sitemap_tree.jsp?" + m.qs() + "&scode=" + code + "';");
	m.jsReplace("sitemap_modify.jsp?" + m.qs());
	return;

}

//상위코드 명
DataSet menus = sitemap.getList();
String pnames = sitemap.getTreeNames(code);
info.put("parent_name", "".equals(pnames) ? "-" : pnames);

//페이지 출력
p.setLayout("blank");
p.setBody("sitemap.sitemap_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("code"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.setLoop("layout_list", sitemap.getLayouts(docRoot + "/html/layout"));
//p.setLoop("modules", m.arr2loop(sitemap.modules));

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