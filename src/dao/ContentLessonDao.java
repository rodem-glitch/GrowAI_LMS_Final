package dao;

import malgnsoft.db.*;

public class ContentLessonDao extends DataObject {

	public ContentLessonDao() {
		this.table = "LM_CONTENT_LESSON";
		this.PK = "CONTENT_ID, CHPATER";
	}

	public void autoSort(int contentId) {
		this.execute("UPDATE " + this.table + " SET chapter = chapter * 1000 WHERE content_id = " + contentId);
		DataSet list = this.find("content_id = " + contentId, "content_id, chapter", "chapter ASC");
		int chapter = 1;
		while(list.next()) {
			this.execute("UPDATE " + this.table + " SET chapter = " + chapter + " WHERE content_id = " + list.i("content_id"));
			chapter++;
		}
	}
}