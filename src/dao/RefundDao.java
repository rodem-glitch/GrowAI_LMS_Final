package dao;

import malgnsoft.db.*;

public class RefundDao extends DataObject {

	public String[] statusList = { "1=>환불요청", "2=>환불완료", "-1=>환불취소/불가" };
	public String[] types = { "1=>부분환불", "2=>전액환불", "3=>환불취소/불가" };
	public String[] refundMethods = { "1=>계좌이체", "2=>결제취소" };
	
	public String[] statusListMsg = { "1=>list.refund.status_list.1", "0=>list.refund.status_list.0" };
	public String[] typesMsg = { "1=>list.refund.types.1", "2=>list.refund.types.2" };
	public String[] refundMethodsMsg = { "1=>list.refund.refund_methods.1", "2=>list.refund.refund_methods.2" };

	public RefundDao() {
		this.table = "TB_REFUND";
	}

}