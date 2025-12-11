package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class UserLogDao extends DataObject {

    public String[] types = { "C=>생성", "R=>조회", "U=>갱신", "D=>삭제", "F=>강제" };
    public String[] modules = {
            "user_insert=>회원", "user_out=>회원탈퇴", "user_modify=>회원수정"
    };
    public String[] statusList = { "1=>정상", "0=>중지" };


    private int siteId = 0;
    private String module = "";

    public UserLogDao() {
        this.table = "TB_USER_LOG";
        this.PK = "id";
    }

    public UserLogDao(int siteId, String module) {
        this.table = "TB_USER_LOG";
        this.PK = "id";

        this.siteId = siteId;
        this.module = module;
    }

    public void setSiteId(int siteId) {
        this.siteId = siteId;
    }

    public void setModule(String module) {
        this.module = module;
    }

    public boolean add(int userId, int moduleId, String type, String desc, String before, String after) {
        this.item("site_id", this.siteId);
        this.item("module", this.module);
        this.item("user_id", userId);
        this.item("module_id", moduleId);
        this.item("action_type", type);
        this.item("action_desc", desc);
        this.item("before_info", before);
        this.item("after_info", after);
        this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
        this.item("status", 1);
        return this.insert();
    }

    public boolean add(int userId, int moduleId, String type, String desc, Form f) {
        DataSet info = new DataSet(); info.addRow();
        return add(userId, moduleId, type, desc, info, f);
    }

    public boolean add(int userId, int moduleId, String type, String desc, DataSet info, Form f) {
        boolean isBefore = !"C".equals(type);
        int i = 0;
        DataSet binfo = new DataSet(); binfo.addRow();
        DataSet ainfo = new DataSet(); ainfo.addRow();
        Hashtable<String,String> map = f.data;
        Enumeration e = map.keys();
        while(e.hasMoreElements()) {
            String key = (String)e.nextElement();
            String fvalue = map.get(key) != null ? map.get(key) : "";
            String ivalue = info.s(key);
            if(key.indexOf("_id") > -1) {
                ivalue = "".equals(ivalue) ? "0" : ivalue;
                fvalue = "".equals(fvalue) ? "0" : fvalue;
            }
            if(
                    !fvalue.equals(ivalue) && !key.startsWith("s_") && !key.startsWith("passwd")
                            && !"uid".equals(key) && !"cuid".equals(key) && !"cid".equals(key) && !"mode".equals(key)
            ) {
                binfo.put(key, ivalue);
                ainfo.put(key, fvalue);
                i++;
            }
        }

        if(i > 0) {
            return this.add(userId, moduleId, type, desc, isBefore ? binfo.serialize() : "", ainfo.serialize());
        } else {
            return true;
        }
    }
}