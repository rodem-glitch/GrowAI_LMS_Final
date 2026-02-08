var TAG = function(module, moduleId, id) {
	if(!module || !moduleId || !id) {
		alert("TAG ERROR - missing required parameter : module, moduleId, id");
		return;
	}
	this.jsonTagList = {};
	this.module = module;
	this.moduleId = moduleId;
	this.id = id;

	if(!$) {
		alert("jQuery is required");
		return;
	}

	this.element = $("#" + id);
	if(!this.element) {
		alert("TAG ERROR - Element not found");
		return;
	}
}

TAG.prototype.getTagIdAttr = function(tag_id) {
	return this.module + "-tag-" + tag_id;
}

TAG.prototype.appendTag = function(tag_id) {
	const tag_nm = this.jsonTagList[tag_id];
	const tag_id_attr = this.getTagIdAttr(tag_id);
	const span_tag =
		"<span id='" + tag_id_attr + "' class='tag' title='" + tag_nm + "'>" + "#" + tag_nm + ""
		+ "<a href=\"javascript:" + (this.initName ? this.initName + "." : "") + "delTag('" + tag_id + "')\"><span class=\"fa fa-times-circle\"></span></a>"
		+ "</span>"
	$("#tag_input").before(span_tag);
}

TAG.prototype.addTagList = function() {
	for(var tag_id in this.jsonTagList) {
		this.appendTag(tag_id);
	}
}

TAG.prototype.addTag = function(tag_nm) {
	tag_nm = tag_nm.replace("#", "");
	$.post("../tag/call_tag.jsp?module=" + this.module + "&mode=add", { "module_id" : this.moduleId, "tag_nm" : tag_nm }, function(ret) {
	}, 'json').then((ret) => {

		if (ret.error === 0) {
			const tag_id = ret?.data?.tag_id;
			this.jsonTagList[tag_id] =  tag_nm;
			this.appendTag(tag_id);

		} else {
			alert(ret.message);
		}

	});
}

TAG.prototype.initTag = function() {
	this.element?.append(
		'<input type="text" id="tag_input" name="tag" maxLength="100" placeholder="#새 태그"/>'
		+ '<span class="desc01">추가할 태그를 입력하고 [,] 또는 [Enter]를 눌러 등록해주세요.</span>'
	);
	const tagInput = $("#tag_input");

	$.post("../tag/call_tag.jsp?module=" + this.module + "&mode=list", { "module_id" : this.moduleId }, function(ret) {
	}, 'json').then((ret) => {

		if (ret.error === 0) {
			const dataList = ret.data.data_list;

			if (dataList.length > 0) {
				dataList.forEach((item, index) => {

					if (!this.jsonTagList) this.jsonTagList = {};
					this.jsonTagList[item.id] = item.tag_nm;
				});
			}
			this.addTagList();
		} else {
			alert(ret.message);
		}
	});

	tagInput.on("keypress", async (e) => {
		var self = $("#tag_input");

		if (e.key === "," || e.keyCode === 44 || e.key === "Enter") { // ,
			const tag_nm = self.val();


			if (tag_nm !== "") {
				await this.addTag(tag_nm);
				self.val("");
			}

			e.preventDefault();
		}
	});
}

TAG.prototype.removeTag = function(tag_id) {
	$("#" + this.getTagIdAttr(tag_id)).remove();
}

TAG.prototype.delTag = function(tag_id) {
	$.post("../tag/call_tag.jsp?module=" + this.module + "&mode=del", { "module_id" : this.moduleId, "tag_id" : tag_id }, function(ret) {
	}, 'json').then((ret) => {
		if (ret.error === 0) {
			delete this.jsonTagList[tag_id];
			this.removeTag(tag_id);
		} else {
			alert(ret.message);
		}
	});
}