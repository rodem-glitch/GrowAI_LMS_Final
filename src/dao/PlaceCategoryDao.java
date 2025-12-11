package dao;

import malgnsoft.db.*;

public class PlaceCategoryDao extends DataObject {

	public PlaceCategoryDao() {
		this.table = "LM_PLACE_CATEGORY";
		this.PK = "place_id,category_id";
	}

	public String getCategory(int placeId) {
		String categories = "";

		DataSet list = this.find("place_id = " + placeId);
		while(list.next()) {
			categories += (!"".equals(categories) ? "," : "") + list.i("category_id");
		}

		return categories;
	}

}