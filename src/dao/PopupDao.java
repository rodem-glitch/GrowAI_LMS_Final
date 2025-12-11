package dao;

import malgnsoft.db.*;

public class PopupDao extends DataObject {

	public String[] types = { "pc=>PC", "mobile=>모바일" };
	public String[] statusList = { "1=>노출", "0=>중지" };
	public String[] statusList2 = { "1=>진행", "2=>대기", "3=>종료", "4=>미사용" };
	public String[] scrollList = { "Y=>사용", "N=>미사용" };
	public String[] templateList = { "Y=>사용", "N=>미사용" };
	public String[] layoutList = { "pop1=>템플릿1" };
//	public String[] layoutList = { "pop1=>템플릿1", "pop2=>템플릿2", "pop3=>템플릿3" };

	public String[] typesMsg = { "pc=>list.popup.types.pc", "mobile=>list.popup.types.mobile" };
	public String[] statusListMsg = { "1=>list.popup.status_list.1", "0=>list.popup.status_list.0" };
	public String[] statusList2Msg = { "1=>list.popup.status_list2.1", "2=>list.popup.status_list2.2", "3=>list.popup.status_list2.3", "4=>list.popup.status_list2.4" };
	public String[] scrollListMsg = { "Y=>list.popup.scroll_list.Y", "N=>list.popup.scroll_list.N" };
	public String[] templateListMsg = { "Y=>list.popup.template_list.Y", "N=>list.popup.template_list.N" };
	public String[] layoutListMsg = { "pop1=>list.popup.layout_list.pop1" };

	public PopupDao() {
		this.table = "TB_POPUP";
	}
}