package dao;

import malgnsoft.db.*;

public class PollDao extends DataObject {

	public String[] statusList = { "1=>사용(노출)", "0=>중지(미사용)" };
	public String[] status2List = { "1=>진행", "2=>대기", "3=>종료", "4=>미사용" };
	
	public String[] statusListMsg = { "1=>list.poll.status_list.1", "0=>list.poll.status_list.0" };
	public String[] status2ListMsg = { "1=>list.poll.status2_list.1", "0=>list.poll.status2_list.0" };

	public PollDao() {
		this.table = "TB_POLL";
	}
}