<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(914, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

//코드체크
if("CHECK".equals(m.rs("mode"))) {
    String value = m.rs("v");
    if("".equals(value)) { return; }

    //중복여부
    if(0 < certificateTemplate.findCount("template_cd = '" + value + "' AND site_id = " + siteId)) {
        out.print("<span class='bad'>사용 중인 코드입니다. 다시 입력해 주세요.</span>");
    } else {
        out.print("<span class='good'>사용할 수 있는 코드입니다.</span>");
    }
    return;
}

//폼체크
f.addElement("template_cd", null, "hname:'템플릿코드', required:'Y', max:20, maxlength:20, pattern:'^[a-z]{1}[a-z0-9_]{1,19}$', errmsg:'영문 소문자로 시작하는 2-10자의 영문 소문자, 숫자, _ 조합으로 입력하세요.'");
f.addElement("template_nm", null, "hname:'템플릿명', required:'Y'");
f.addElement("background_file", null, "hname:'배경이미지', allow:'jpg|jpeg|gif|png'");
if(1 == siteId) f.addElement("base_yn", "Y", "hname:'기본템플릿여부', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

    //중복검사-코드
    if(0 < certificateTemplate.findCount("template_cd = '" + f.get("template_cd") + "' AND site_id = " + siteId)) { m.jsAlert("사용 중인 코드입니다. 다시 입력해 주세요."); return; }

    certificateTemplate.item("site_id", siteId);
    certificateTemplate.item("template_cd", f.get("template_cd"));
    certificateTemplate.item("template_nm", f.get("template_nm"));
    certificateTemplate.item("content", f.get("content"));
    if(1 == siteId) certificateTemplate.item("base_yn", f.get("base_yn", "N"));
    certificateTemplate.item("reg_date", m.time("yyyyMMddHHmmss"));
    certificateTemplate.item("status", f.get("status", "0"));

    boolean isUpload = false;
    if(null != f.getFileName("background_file")) {
        File f1 = f.saveFile("background_file");
        if(f1 != null) {
            certificateTemplate.item("background_file", f.getFileName("background_file"));
            isUpload = true;
        }
    }
    if(!certificateTemplate.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

    //파일리사이징
    if(isUpload) {
        try {
            String imgPath = m.getUploadPath(f.getFileName("course_file"));
            String cmd = "convert -resize 1000x> " + imgPath + " " + imgPath;
            Runtime.getRuntime().exec(cmd);
        }
        catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
        catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
    }

    m.jsReplace("template_list.jsp?" + m.qs(), "parent");
    return;
}

//출력
p.setBody("certificate.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(certificateTemplate.statusList));
p.display();

%>