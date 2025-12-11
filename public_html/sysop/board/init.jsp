<%@ include file="../init.jsp"%><%

//아이디
String code = m.rs("code");
String md = "post";

//객체
BoardDao board = new BoardDao();
CategoryDao category = new CategoryDao();
PostDao post = new PostDao();
CommentDao comment = new CommentDao();
FileDao file = new FileDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//정보-게시판
//board.d(out);
DataSet binfo = board.find(
	"code = '" + code + "' AND status != -1 AND site_id = " + siteId + ""
	+ (!("A".equals(userKind) || "S".equals(userKind)) ? " AND admin_idx LIKE '%|" + userId + "|%'" : "")
);
if(!binfo.next()) { m.jsError("해당 게시판이 없습니다."); return; }

binfo.put("notice_block", binfo.b("notice_yn"));
binfo.put("category_block", binfo.b("category_yn"));
binfo.put("upload_block", binfo.b("upload_yn"));
binfo.put("reply_block", binfo.b("reply_yn"));
binfo.put("comment_block", binfo.b("comment_yn"));

//환경설정-모듈/타입/스킨/새글기준
String btype = binfo.s("board_type");
boolean isBoardAdmin = true;
p.setVar(btype + "_type_block", true);

int bid = binfo.i("id");
int newHour = 24;											//새글기준(시간)
int columnCnt = 5;											//갤러리용 컬럼수
int listNum = 20;
p.setVar("contentwidth", post.getContentWidth());

DataSet categories = binfo.b("category_yn") ? category.getList("board", bid, siteId) : new DataSet();	//카테고리

//채널
String ch = "sysop";

%>