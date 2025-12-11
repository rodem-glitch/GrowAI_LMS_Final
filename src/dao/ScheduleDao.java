package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class ScheduleDao extends DataObject {

	public ScheduleDao() {
		this.table = "TB_SCHEDULE";
	}
	public DataSet getfields() {
		DataSet fields = new DataSet();

		fields.addRow();
		fields.put("id", "request_sdate"); fields.put("name", "수강신청 시작"); fields.put("icon", "ⓢ"); fields.put("color", "blue");
		fields.addRow();
		fields.put("id", "request_edate"); fields.put("name", "수강신청 종료"); fields.put("icon", "ⓔ"); fields.put("color", "blue");
		fields.addRow();
		fields.put("id", "study_sdate"); fields.put("name", "학습 시작"); fields.put("icon", "ⓢ"); fields.put("color", "red");
		fields.addRow();
		fields.put("id", "study_edate"); fields.put("name", "학습 종료"); fields.put("icon", "ⓔ"); fields.put("color", "red");
		fields.first();
		return fields;
	}
}