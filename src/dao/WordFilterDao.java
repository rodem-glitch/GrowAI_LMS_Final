package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

import java.util.Hashtable;

public class WordFilterDao extends DataObject {

    private static Hashtable<String, DataSet> cache = new Hashtable<String, DataSet>();
    private DataSet words = null;
    private String siteId = "0";

    public WordFilterDao() {
        this.table = "TB_WORD_FILTER";
        this.PK = "id";
        this.useSeq = "N";
    }

    public DataSet getDataSet() {
        DataSet list = cache.get(siteId);
        if(list == null) {
            list = find("");
            cache.put(siteId, list);
        }
        this.words = list;
        return list;
    }

    public int add(String word) {

        this.item("word", word);
        this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
        int id = this.insert(true);
        if(id > 0) {
            DataSet info = this.find("id = " + id); info.next();
            if(this.words == null) this.getDataSet();
            this.words.addRow(info.getRow());
        }
        return id;
    }

    //보유중인 단어 중 일치하는 것이 있으면 반환
    public boolean check(String content) {
        if(this.words == null) this.getDataSet();
        words.first();
        while(words.next()) {
            if(content.contains(words.s("word"))) return true;
        }
        return false;
    }

    public void clear() {
        cache.clear();
    }

}