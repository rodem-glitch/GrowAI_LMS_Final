package dao;

import malgnsoft.db.*;

public class FileDao extends DataObject {

	public String allowExt = "jpg|jpeg|gif|png|pdf|hwp|txt|doc|docx|xls|xlsx|ppt|pptx|zip|alz|7z|rar|egg|mp3";

	public FileDao() {
		this.table = "TB_FILE";
	}

	public RecordSet getFileList(int mid) {
		return getFileList(mid, "post");
	}

	public RecordSet getFileList(int mid, String module) {
		return getFileList(mid, module, true);
	}

	public RecordSet getFileList(int mid, String module, boolean imageYn) {
		return find("module = '" + module + "' AND module_id = " + mid + " AND status > 0" + (!imageYn ? " AND realname NOT REGEXP 'jpg|jpeg|png|gif'" : ""), "*", "id ASC");
	}

	public int updateTempFile(int temp_id, int mid, String module) {
		return execute("UPDATE " + table + " SET module_id = " + mid + " WHERE module = '" + module + "' AND module_id = " + temp_id);
	}

	public int getFileCount(int mid, String module) {
		return findCount("module = '" + module + "' AND module_id = " + mid);
	}

	public String getFileExt(String filename) {
		filename = filename.toLowerCase();
		return filename.substring(filename.lastIndexOf(".") + 1, filename.length());
	}

	public String getFileIcon(String filename) {
		//return "<img src=\"/sysop/html/images/admin/ext/" + getFileExt(filename) + ".gif\" width=\"16\" height=\"16\" align=\"absmiddle\" onError=\"this.src='/sysop/html/images/admin/ext/unknown.gif'\"> ";
		return "<img src=\"/common/images/ext/" + getFileExt(filename) + ".gif\" width=\"16\" height=\"16\" align=\"absmiddle\" onError=\"this.src='/common/images/ext/unknown.gif'\"> ";
	}

	public int updateDownloadCount(int id) {
		return execute("UPDATE " + table + " SET download_cnt = download_cnt + 1 WHERE id = " + id);
	}

	public String getFileSize(long size) {
		if(size >= 1024 * 1024 * 1024) return (int)Math.ceil(size / (1024.0 * 1024 * 1024)) + "GB";
		else if(size >= 1024 * 1024) return (int)Math.ceil(size / (1024.0 * 1024)) + "MB";
		else if(size >= 1024) return (int)Math.ceil(size / 1024.0) + "KB";
		else return (int)Math.ceil(size * 1.0) + "B";
	}
}