package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class ClFileDao extends DataObject {

	public ClFileDao() {
		this.table = "CL_FILE";
	}
	public int updateTempFile(int tempId, int postId) {
		return updateTempFile(tempId, postId, "post");
	}
	public int updateTempFile(int tempId, int postId, String module) {
		return execute("UPDATE "+ table +" SET module_id = " + postId + " WHERE module = '" + module + "' AND module_id = " + tempId);
	}

	public String getFileType(String filename) {
		filename = filename.toLowerCase();
		String type = "";
		if(filename.matches("^(.+)(jpg|gif|png|bmp|jpeg|tiff|tif)$")) type = "image";
		else if(filename.matches("^(.+)(swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra)$")) type = "movie";
		else type = "file";
		return type;
	}

	public int updateDownloadCount(int id) {
		return execute("UPDATE " + table + " SET download_cnt = download_cnt + 1 WHERE id = " + id);
	}

/*
	public void updateFtype(int moduleId) {
		DataSet list = query("SELECT filetype FROM " + table + " WHERE module = 'post' AND module_id = '" + moduleId + "' AND status = 1 GROUP BY filetype");
		String type = "";
		while(list.next()) { type += "," + list.getString("filetype"); }
		if(!"".equals(type)) {
			type = type.substring(1, type.length());
		}
		execute("UPDATE " + new ClPostDao().table + " SET ftype_cnt = '" + type + "' WHERE id = '" + moduleId + "'");
	}
*/
	public String getFileExt(String filename) {
		filename = filename.toLowerCase();
		return filename.substring(filename.lastIndexOf(".") + 1, filename.length());
	}
	public String getFileIcon(String filename) {
		//return "<img src=\"/sysop/html/images/admin/ext/" + getFileExt(filename) + ".gif\" width=\"16\" height=\"16\" align=\"absmiddle\" onError=\"this.src='../html/images/admin/ext/unknown.gif'\"> ";
		return "<img src=\"/common/images/ext/" + getFileExt(filename) + ".gif\" width=\"16\" height=\"16\" align=\"absmiddle\" onError=\"this.src='/common/images/ext/unknown.gif'\"> ";
	}
}