package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class FreepassDao extends DataObject {

	public String[] statusList = {"1=>정상", "0=>중지"};
	public String[] displayYn = { "Y=>보임", "N=>숨김" };
	public String[] saleYn = { "Y=>판매", "N=>중지" };
	
	public String[] statusListMsg = { "1=>list.freepass.status_list.1", "0=>list.freepass.status_list.0" };
	public String[] displayYnMsg = { "Y=>list.freepass.display_yn.Y", "N=>list.freepass.display_yn.N" };
	public String[] saleYnMsg = { "Y=>list.freepass.sale_yn.Y", "N=>list.freepass.sale_yn.N" };

	private int siteId = 0;

	public FreepassDao() {
		this.table = "TB_FREEPASS";
		this.PK = "id";
	}

	public FreepassDao(int siteId) {
		this.table = "TB_FREEPASS";
		this.PK = "id";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
	}

}