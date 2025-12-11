package dao;

import malgnsoft.db.*;

public class DeliveryDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.delivery.status_list.1", "0=>list.delivery.status_list.0" };

	public DeliveryDao() {
		this.table = "TB_DELIVERY";
	}

}