<%@ include file="/init.jsp"%><%

//폼입력
String code = m.rs("code", "notice");

//객체
BoardDao board = new BoardDao();
PostDao post = new PostDao();
FileDao file = new FileDao();
CategoryDao category = new CategoryDao();


//정보
DataSet binfo = board.find("code = ? AND site_id = " + siteId + " AND status = 1", new String[] { code });
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }


String ch = "mobile";

String btype = binfo.s("board_type");
int bid = binfo.i("id");
int newHour = 24;
int listNum = binfo.i("list_num");		//사용자-10
if(listNum < 10) listNum = 10;
if(listNum > 100) listNum = 100;
boolean isBoardAdmin = 0 != userId && ("S".equals(userKind) || Menu.accessible(80, userId, userKind, false) || -1 < binfo.s("admin_idx").indexOf("|" + userId + "|"));
DataSet categories = binfo.b("category_yn") ? category.getList("board", bid, siteId) : new DataSet();	//카테고리

p.setVar(code + "_board_block", true);
p.setVar(btype + "_type_block", true);

%>