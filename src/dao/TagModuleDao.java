package dao;

import malgnsoft.db.*;

public class TagModuleDao extends DataObject {

	public String[] moduleList = { "course=>과정" };

	private String module = "course";

	private int limit = 20;

	public TagModuleDao() {
		this.table = "TB_TAG_MODULE";
		this.PK = "tag_id,module,module_id";
	}

	public TagModuleDao(String module) {
		this.table = "TB_TAG_MODULE";
		this.module = module;
		this.PK = "tag_id,module,module_id";
	}

	public void setModule(String module) {
		this.module = module;
	}

	public boolean addTag(int tagId, int moduleId) {
		return addTag(tagId, this.module, moduleId);
	}

	public boolean addTag(int tagId, String module, int moduleId) {

		this.item("tag_id", tagId);
		this.item("module", module);
		this.item("module_id", moduleId);

		return this.insert();
	}

	public DataSet getTagList(int moduleId) {
		return getTagList(this.module, moduleId, this.limit);
	}

	public DataSet getTagList(String module, int moduleId) {
		return getTagList(module, moduleId, this.limit);
	}

	public DataSet getTagList(int moduleId, int limit) {
		return getTagList(this.module, moduleId, limit);
	}

	public DataSet getTagList(String module, int moduleId, int limit) {
		return this.query(
			"SELECT t.id tag_id, t.tag_nm "
				+ " FROM " + this.table + " tm "
				+ " INNER JOIN " + new TagDao().table + " t ON tm.tag_id = t.id "
				+ " WHERE t.status = 1 "
				+ " AND tm.module = '" + module + "' AND tm.module_id = " + moduleId
				+ " ORDER BY t.sort ASC, t.id ASC "
			, limit
		);
	}

}
