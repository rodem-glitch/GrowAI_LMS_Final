package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class CertificateTemplateDao extends DataObject {

    private int siteId;

    public String[] statusList = {"1=>정상", "0=>중지"};

    public CertificateTemplateDao() {
        this.table = "TB_CERTIFICATE_TEMPLATE";
        this.PK = "id";
    }

    public CertificateTemplateDao(int siteId) {
        this.table = "TB_CERTIFICATE_TEMPLATE";
        this.PK = "id";
        this.siteId = siteId;
    }

    public DataSet getList(int siteId) {
        return this.find("site_id = " + siteId + " AND status = 1", "*", "reg_date DESC");
    }

    public String getTemplate(int siteId, String templateCd) {
        return this.getOne("SELECT content FROM " + this.table + " WHERE site_id = " + siteId + " AND template_cd = '" + templateCd + "' AND status = 1");
    }

    public String fetchTemplate(int siteId, String templateCd, Page p) throws Exception {
        if(siteId == 0 || "".equals(templateCd) || p == null) return "";
        return p.fetchString(this.getTemplate(siteId, templateCd));
    }

    public int copyTemplate(int siteId) {
        if(0 == siteId) return -1;

        DataSet list = this.find("site_id = 1 AND base_yn = 'Y'");
        String[] columns = list.getColumns();
        String now = Malgn.time("yyyyMMddHHmmss");
        int success = 0;
        while(list.next()) {
            for(int i = 0; i < columns.length; i++) { this.item(columns[i], list.s(columns[i])); }
            this.item("id", this.getSequence());
            this.item("site_id", siteId);
            this.item("reg_date", now);
            if(1 > this.findCount("site_id = " + siteId + " AND template_cd = '" + list.s("template_cd") + "'") && this.insert()) success++;
        }

        return success;
    }

    public int copyTemplate(String templateCd) {
        if("".equals(templateCd)) return -1;

        SiteDao site = new SiteDao(); site.jndi = this.jndi;

        DataSet info = this.find("template_cd = ? AND site_id = 1 AND base_yn = 'Y'", new String[] { templateCd });
        if(!info.next()) return -1;

        String[] columns = info.getColumns();
        String now = Malgn.time("yyyyMMddHHmmss");
        int success = 0;

        DataSet slist = site.find("id != 1 AND status != -1");
        while(slist.next()) {
            for(int i = 0; i < columns.length; i++) { this.item(columns[i], info.s(columns[i])); }
            this.record.remove("id");
            this.item("site_id", slist.s("id"));
            this.item("reg_date", now);
            this.item("background_file", "");
            if(1 > this.findCount("site_id = " + slist.s("id") + " AND template_cd = '" + templateCd + "'")) {
                if(this.insert()) success++;
            } else {
                if(this.update("site_id = " + slist.s("id") + " AND template_cd = '" + templateCd + "'")) success++;
            }
        }

        return success;
    }
}