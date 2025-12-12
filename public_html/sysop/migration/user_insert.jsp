<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

String pattern = "(\\d{3})(\\d{3,4})(\\d{4})";

//등록
if(m.isPost()) {
    //변수
    DataSet list = new DataSet();
    
    //엑셀파일
    File f1 = f.saveFile("file");
    if(f1 != null) {
        DataSet records = new DataSet();
        String path = m.getUploadPath(f.getFileName("file"));
        try {
            records = new ExcelReader(path).getDataSet(1);
        } catch(Exception e) {
            m.jsAlert("호환되지 않거나 손상된 파일입니다.");
            return;
        }
        if(!"".equals(path)) m.delFileRoot(path);
        
        //포맷팅
        int idx = 0;
        while(records.next()) {
            if(!"".equals(records.s("col0"))) {
                list.addRow();
                list.put("__idx", ++idx);
                list.put("login_id", records.s("col0"));
                list.put("user_nm", records.s("col1"));
                list.put("passwd", m.encrypt(records.s("col2"), "SHA-256"));
                list.put("user_kind", f.get("user_kind", "U"));
                list.put("email", records.s("col3"));
                list.put("mobile", (!"".equals(records.s("col4")) ? SimpleAES.encrypt(records.s("col4").replaceAll(pattern, "$1-$2-$3")) : ""));
                System.out.println(records.s("col4").replaceAll(pattern, "$1-$2-$3"));
                list.put("birthday", (8 != records.s("col5").length() ? m.time("yyyyMMdd") : m.time("yyyyMMdd", records.s("col5"))));
                list.put("gender", (0 < records.i("col6") && 3 > records.i("col6") ? records.i("col6") : 1));
                list.put("dept_id", (0 < records.i("col7") ? records.i("col7") : f.getInt("dept_id")));
                list.put("zipcode", records.s("col8"));
                list.put("new_addr", records.s("col9"));
                list.put("addr_dtl", records.s("col10"));
                list.put("reg_date", (14 != records.s("col11").length() ? m.time("yyyyMMddHHmmss") : m.time("yyyyMMddHHmmss", records.s("col11"))));
                list.put("etc1", records.s("col12"));
                list.put("etc2", records.s("col13"));
                list.put("etc3", records.s("col14"));
                list.put("etc4", records.s("col15"));
                list.put("etc5", records.s("col16"));
            }
        }
        
    } else {
        m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
        return;
    }
    
    //회원등록
    int success = 0;
    int failed = 0;
    StringBuilder failedUser = new StringBuilder();
    
    user.item("site_id", siteId);
    user.item("display_yn", "N");
    user.item("email_yn", "N");
    user.item("sms_yn", "N");
    user.item("privacy_yn", "N");
    //FAIL_CNT는 로그인 실패횟수로 TB_USER에서 NOT NULL입니다. 마이그레이션 등록도 0으로 시작하도록 기본값을 넣어줍니다.
    user.item("fail_cnt", 0);
    user.item("passwd_date", m.time("yyyyMMdd"));
    user.item("status", 1);
    
    list.first();
    while(list.next()) {
        
        //중복검사
        if(0 < user.findCount("login_id = '" + list.s("login_id") + "' AND site_id = " + siteId)) {
            failedUser.append("실패회원[").append(failed).append("] : ");
            failedUser.append(list.s("login_id")).append(",").append(list.s("user_nm")).append(",");
            failed++;
            continue;
        }
        
        int newId = user.getSequence();
        user.item("id", newId);
        user.item("login_id", list.s("login_id"));
        user.item("user_nm", list.s("user_nm"));
        user.item("passwd", list.s("passwd"));
        user.item("user_kind", list.s("user_kind"));
        user.item("email", list.s("email"));
        user.item("mobile", list.s("mobile"));
        user.item("birthday", list.s("birthday"));
        user.item("gender", list.s("gender"));
        user.item("dept_id", list.s("dept_id"));
        user.item("zipcode", list.s("zipcode"));
        user.item("new_addr", list.s("new_addr"));
        user.item("addr_dtl", list.s("addr_dtl"));
        user.item("reg_date", list.s("reg_date"));
        user.item("etc1", list.s("etc1"));
        user.item("etc2", list.s("etc2"));
        user.item("etc3", list.s("etc3"));
        user.item("etc4", list.s("etc4"));
        user.item("etc5", list.s("etc5"));
        
        if(!user.insert()) failed++;
        else success++;
    }
    
    m.jsAlert(success + "건 성공 / " + failed + "건 실패 " + failedUser);
    m.js("try { parent.location.href = parent.location.href; } catch(e) { }");
    return;
}

//출력
p.setLayout("sysop");
p.setBody("migration.user_insert");
p.setVar("p_title", "회원일괄등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("tab_user", "current");
p.setLoop("dept_list", userDept.getList(siteId));

p.display();

%>
