$(window).load(function(){
	// 왼쪽메뉴열기_모바일
	$("body").on("click ", ".btnMenu", function(){
		$("#left_menu").addClass('view');
		$("#wrap").addClass("noScroll");
		$(".mask_popup").addClass('view');
	});

	// 왼쪽메뉴닫기_모바일
	$("body").on("click ", ".btnMenu_mClose", function(){
		$("#left_menu").removeClass('view');
		$("#wrap").removeClass("noScroll");
		$(".mask_popup").removeClass('view');
	});


	// wrap클릭시 메뉴닫기
	$("body").on("click ", ".mask_popup", function(){
		$("#left_menu").removeClass('view');
		$("#wrap").removeClass("noScroll");
		$(".mask_popup").removeClass('view');
	});


	// 왼쪽 하위 메뉴
	$("body").on("click ", "#left_menu .left_menu>.list>li", function(){
		var idx = $("#left_menu .left_menu>.list>li").index($(this));
		$("#left_menu .left_menu>.list>li").each(function(index){
			if(idx == index){
				if(!$(this).hasClass("bgColor")){
					$(this).addClass("bgColor");
					$(this).find(".sMenu").slideDown(300);
				}else{
					$(this).removeClass("bgColor");
					$(this).find(".sMenu").slideUp(300);
				}
			}else{
				$(this).removeClass("bgColor");
				$(this).find(".sMenu").slideUp(300);
			}
		});
	});
});


/*메인메뉴 gnb*/
$(function(){
	$("#left_menu .left_menu .list .sMenu li a").mouseover(function(){
		$(this).addClass("pointColor");
	}).mouseleave(function(){
		$(this).removeClass("pointColor");
	});
});


$(document).ready(function(){
	$('.tab_button').on("click", function(){
		$('#wrap').toggleClass('close');
		$('#contWrap').toggleClass('close');
	});
});

$(window).on('load resize', function(){
	if (window.innerWidth > 680 ){
		$("#left_menu").removeClass('view');
		$("#wrap").removeClass("noScroll");
		$(".mask_popup").removeClass('view');
	}else{
		$('#wrap').removeClass('close');
		$('#contWrap').removeClass('close');
	}
});
