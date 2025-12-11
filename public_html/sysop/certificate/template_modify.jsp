<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(914, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//카테고리
DataSet categories = category.getList(siteId);

//정보
DataSet info = certificateTemplate.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), certificateTemplate.statusList));

//템플릿복사
if(1 == siteId && "COPY".equals(m.rs("mode"))) {
    m.jsAlert(certificateTemplate.copyTemplate(info.s("template_cd")) + "개 사이트에 복사되었습니다.");
    m.jsReplace("template_modify.jsp?" + m.qs("mode"));
    return;
}

//파일삭제
if("fdel".equals(m.rs("mode"))) {
    if(!"".equals(info.s("background_file"))) {
        certificateTemplate.item("background_file", "");
        if(certificateTemplate.update("id = " + id)) {
            m.delFileRoot(m.getUploadPath(info.s("background_file")));
        }
    }
    return;
}

//폼체크
f.addElement("template_nm", info.s("template_nm"), "hname:'템플릿명', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if(1 == siteId) f.addElement("base_yn", info.s("base_yn"), "hname:'기본템플릿여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y', option:'number'");

//수정
if(m.isPost() && f.validate()) {

    certificateTemplate.item("template_nm", f.get("template_nm"));
    certificateTemplate.item("content", f.get("content"));
    if(1 == siteId) certificateTemplate.item("base_yn", f.get("base_yn", "N"));
    certificateTemplate.item("status", f.get("status", "0"));

    boolean isUpload = false;
    if(null != f.getFileName("background_file")) {
        File f1 = f.saveFile("background_file");
        if(f1 != null) {
            isUpload = true;
            certificateTemplate.item("background_file", f.getFileName("background_file"));
            if(!"".equals(info.s("background_file")) && new File(m.getUploadPath(info.s("background_file"))).exists()) {
                m.delFileRoot(m.getUploadPath(info.s("background_file")));
            }
        }
    }

    //파일리사이징
    if(isUpload) {
        try {
            String imgPath = m.getUploadPath(f.getFileName("background_file"));
            String cmd = "convert -resize 1000x> " + imgPath + " " + imgPath;
            Runtime.getRuntime().exec(cmd);
        }
        catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
        catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
    }

    if(!certificateTemplate.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

    //이동
    m.js("parent.location.href = parent.location.href;");
    return;
}

//포맷팅
info.put("background_file_conv", m.encode(info.s("background_file")));
info.put("background_file_url", m.getUploadUrl(info.s("background_file")));
info.put("background_file_ek", m.encrypt(info.s("background_file") + m.time("yyyyMMdd")));

DataSet clist = course.find(" site_id = ? AND status != ? AND cert_template_id = ? ", new Object[]{ siteId, -1, id });

while(clist.next()) {
    clist.put("course_nm_conv", m.cutString(clist.s("course_nm"), 80));
    clist.put("cate_name", category.getTreeNames(clist.i("category_id")));
    clist.put("status_conv", m.getItem(clist.s("status"), course.statusList));
    clist.put("package_block", "P".equals(clist.s("onoff_type")));
    clist.put("alltimes_block", "A".equals(clist.s("course_type")));
    clist.put("regular_block", "R".equals(clist.s("course_type")));
    clist.put("onoff_type_conv", m.getItem(clist.s("onoff_type"), course.onoffPackageTypes));
    clist.put("request_sdate_conv", m.time("yyyy.MM.dd", clist.s("request_sdate")));
    clist.put("request_edate_conv", m.time("yyyy.MM.dd", clist.s("request_edate")));
    clist.put("study_sdate_conv", m.time("yyyy.MM.dd", clist.s("study_sdate")));
    clist.put("study_edate_conv", m.time("yyyy.MM.dd", clist.s("study_edate")));
}

//출력
p.setBody("certificate.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("course_list", clist);
p.setLoop("status_list", m.arr2loop(certificateTemplate.statusList));

p.display();

%>