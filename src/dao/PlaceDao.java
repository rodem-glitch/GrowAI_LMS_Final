package dao;

import malgnsoft.db.*;

public class PlaceDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] displayYn = { "Y=>노출", "N=>숨김" };
	
	public String[] statusListMsg = { "1=>list.place.status_list.1", "0=>list.place.status_list.0" };
	public String[] displayYnMsg = { "Y=>list.place.display_yn.Y", "N=>list.place.display_yn.N" };

	public PlaceDao() {
		this.table = "LM_PLACE";
	}
}