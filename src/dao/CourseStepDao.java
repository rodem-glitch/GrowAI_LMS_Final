package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CourseStepDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] statusListMsg = { "1=>list.course_step.status_list.1", "0=>list.course_step.status_list.0" };

	public CourseStepDao() {
		this.table = "LM_COURSE_STEP";
	}

	public DataSet getStepList() {
		DataSet list = new DataSet();
		for(int i=1,max=24;i<=max; i++) { list.addRow(); list.put("id", i); list.put("name", i+"기"); }
		list.first();
		return list;
	}
}