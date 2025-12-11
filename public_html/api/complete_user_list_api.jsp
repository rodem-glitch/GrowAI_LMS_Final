<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

    //기본키
    String sdate = m.time("yyyyMMdd", m.rs("sdate"));
    String edate = m.time("yyyyMMdd", m.rs("edate"));
    String status = m.rs("status");
    int cid = m.ri("cid");
    int uid = m.ri("uid");
    if(!error && ("".equals(sdate) || "".equals(edate) || 0 > m.diffDate("D", sdate, edate))) {
        _ret.put("ret_code", "310");
        _ret.put("ret_msg", "not valid information");
        error = true;
    }

//객체
    UserDao user = new UserDao();
    CourseDao course = new CourseDao();
    CourseUserDao courseUser = new CourseUserDao();

//목록
    DataSet list = null;
    String keyDate = "";
    Hashtable<String, Hashtable> retMap = new Hashtable<String, Hashtable>();
    if(!error) {
        ArrayList<String> qs = new ArrayList<String>();
        qs.add(sdate + "000000");
        qs.add(edate + "235959");
        if(cid > 0) qs.add(cid + "");
        if(uid > 0) qs.add(uid + "");
        if(!"".equals(status)) qs.add(status);

        //courseUser.d(out);
        list = courseUser.query(
                " SELECT a.id, a.course_id, c.year, c.step, c.onoff_type, c.course_type, c.course_nm, a.user_id, u.login_id, u.user_nm, u.birthday, u.mobile "
                        + " , a.start_date, a.end_date, a.credit, a.total_score, a.progress_ratio, a.complete_no, a.complete_date AS complete_time, LEFT(a.complete_date, 8) AS complete_date, a.status, a.reg_date "
                        + " FROM " + courseUser.table + " a "
                        + " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status != -1 "
                        + " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1"
                        + " WHERE a.complete_yn = 'Y' AND a.complete_date >= ? AND a.complete_date <= ? "
                        + (cid > 0 ? " AND a.course_id = ? " : "")
                        + (uid > 0 ? " AND a.user_id = ? " : "")
                        + (!"".equals(status) ? " AND a.status = ? " : "")
                        + " AND a.site_id = " + siteId + " AND a.status != -1 "
                        + " ORDER BY complete_date ASC, id ASC "
                , qs.toArray()
        );
        //포맷팅
        DataSet temp = new DataSet();
        while(list.next()) {
            if(!"".equals(keyDate) && !list.s("complete_date").equals(keyDate)) addMapData(retMap, keyDate, temp);

            list.put("mobile_conv", !"".equals(list.s("mobile")) ? SimpleAES.decrypt(list.s("mobile")) : "");

            keyDate = list.s("complete_date");
            temp.addRow();
            temp.put("id", list.s("id"));
            temp.put("course_id", list.s("course_id"));
            temp.put("year", list.s("year"));
            temp.put("step", list.s("step"));
            temp.put("onoff_type", list.s("onoff_type"));
            temp.put("course_type", list.s("course_type"));
            temp.put("course_nm", list.s("course_nm"));
            temp.put("credit", list.s("credit"));
            temp.put("user_id", list.s("user_id"));
            temp.put("login_id", list.s("login_id"));
            temp.put("user_nm", list.s("user_nm"));
            temp.put("birthday", list.s("birthday"));
            temp.put("mobile", list.s("mobile_conv"));
            temp.put("start_date", list.s("start_date"));
            temp.put("end_date", list.s("end_date"));
            temp.put("total_score", list.s("total_score"));
            temp.put("progress_ratio", list.s("progress_ratio"));
            temp.put("complete_no", list.s("complete_no"));
            temp.put("complete_date", list.s("complete_date"));
            temp.put("complete_time", list.s("complete_time"));
            temp.put("reg_date", list.s("reg_date"));
            temp.put("status", list.s("status"));
        }
        if(!"".equals(keyDate)) addMapData(retMap, keyDate, temp);
        _ret.put("ret_size", list.size());
    }
//수정
    if(!apiLog.updateLog(_ret.get("ret_code").toString())) {
        _ret.put("ret_code", "-1");
        _ret.put("ret_msg", "cannot modify db");
        list = null;
        error = true;
    };

//출력
    DataSet retData = new DataSet();
    if(0 < retMap.size()) retData.addRow(retMap);
    apiLog.printList(out, _ret, retData);

%><%!
    public void addMapData(Hashtable<String, Hashtable> retMap, String key, DataSet list) {
        Hashtable<String, Object> sub = new Hashtable<String, Object>();
        sub.put("sub_size", list.size());
        sub.put("sub_data", new DataSet(list));
        retMap.put(key, sub);
        list.removeAll();
    }
%>