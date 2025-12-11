package dao;

import malgnsoft.db.*;

public class KollusLogDao extends DataObject {

    public KollusLogDao() {
        this.table = "LM_KOLLUS_LOG";
        this.setInsertIgnore(true);
    }
    
}