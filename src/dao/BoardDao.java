package dao;

import java.io.File;
import malgnsoft.db.*;
import malgnsoft.util.*;

public class BoardDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] extTypes = { "image=>|jpg|jpeg|gif|png", "media=>|swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra" };
	public String[] types = { "board=>목록형", "qna=>Q&A형", "faq=>FAQ형", "youtube=>유튜브형", "gallery=>갤러리형", "webzine=>웹진형" };

	public String[] statusListMsg = { "1=>list.board.status_list.1", "0=>list.board.status_list.0" };
	public String[] typesMsg = { "board=>list.board.types.board", "qna=>list.board.types.qna", "faq=>list.board.types.faq", "youtube=>list.board.types.youtube", "gallery=>list.board.types.gallery", "webzine=>list.board.types.webzine" };

	public String[] exceptions = { "notice", "pds", "qna", "faq" };

	public String[] config = { "boardFreeType=>Y" , "boardListNum=>N" , "boardGuest=>Y" , "boardConfirm=>N" , "boardSecret=>N" , "boardAdvComm=>Y" };

	public BoardDao() {
		this.table = "TB_BOARD";
	}

	public String config(String key) {
		return Malgn.getItem(key, config);
	}

	public DataSet getLayouts(String path) throws Exception {
		DataSet ds = new DataSet();
		try {
			File dir = new File(path);
			if (!dir.exists()) return ds;

			File[] files = dir.listFiles();
			if(null == files) throw new NullPointerException();
			for (int i = 0; i < files.length; i++) {
				if(null == files[i]) throw new NullPointerException();
				String filename = files[i].getName();
				if (filename.startsWith("layout_")) {
					ds.addRow();
					ds.put("id", filename.substring(7, filename.length() - 5));
					ds.put("name", filename);
				}
			}

			return ds;
		} catch (NullPointerException npe) {
			Malgn.errorLog("NullPointerException : BoardDao.getLayouts() : " + npe.getMessage(), npe);
			return new DataSet();
		}

	}

	public DataSet getSkins(String path) throws Exception {
		DataSet ds = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return ds;

		try {
			File[] files = dir.listFiles();
			if(null == files) throw new NullPointerException();
			for (int i = 0; i < files.length; i++) {
				if(null == files[i]) throw new NullPointerException();
				if (files[i].isDirectory()) {
					String filename = files[i].getName();
					if (!"comment".equals(filename)) {
						ds.addRow();
						ds.put("id", filename);
						ds.put("name", filename);
					}
				}
			}
			return ds;
		} catch (NullPointerException npe) {
			Malgn.errorLog("NullPointerException : BoardDao.getSkins() : " + npe.getMessage(), npe);
			return new DataSet();
		}
	}

	public DataSet getLevels() {
		return new DataSet();
	}
	
	/*
	** UPDATE TB_BOARD SET auth_list = '|A|T|U|0|', auth_read = '|A|T|U|0|', auth_write = '|A|T|U|', auth_reply = '|A|T|U|', auth_comm = '|A|T|U|' WHERE id =
	*/
	

	//권한검사
	public boolean accessible(String type, int id, String userGroups, String userKind) {
		if("".equals(type) || id == 0) return false;
		if("S".equals(userKind)) return true;

		if("".equals(userGroups)) userGroups = "0";
		userGroups += "," + userKind;

		boolean ret = false;
		DataSet info = this.find("id = " + id + "");
		if(!info.next()) return false;
		
		String[] authList = userGroups.split("\\,");
		String groups = info.s("auth_" + type);
		if("".equals(groups)) return false;

		for (int i = 0; i < authList.length; i++){
			if(groups.indexOf("|" + authList[i] + "|") > -1) ret = true;
		}

		return ret;
	}
}