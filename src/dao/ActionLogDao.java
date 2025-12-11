package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class ActionLogDao extends DataObject {

	public String[] types = { "C=>생성", "R=>조회", "U=>갱신", "D=>삭제" };
	public String[] statusList = { "1=>정상", "0=>중지" };

	public String[] typesMsg = { "C=>list.action_log.types_msg.C", "R=>list.action_log.types_msg.R", "U=>list.action_log.types_msg.U", "D=>list.action_log.types_msg.D" };
	public String[] statusListMsg = { "1=>list.action_log.status_list.1", "0=>list.action_log.status_list.0" };

	private int siteId = 0;
	private String module = "";

	public ActionLogDao() {
		this.table = "TB_ACTION_LOG";
		this.PK = "id";
	}

	public ActionLogDao(int siteId, String module) {
		this.table = "TB_ACTION_LOG";
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
}