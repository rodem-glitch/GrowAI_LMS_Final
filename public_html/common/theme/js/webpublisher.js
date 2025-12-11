//GNB fixed
	var didScroll;
	var lastScrollTop = 0;
	var delta = 5;
	var navbarHeight = $('header').outerHeight();

	$(window).scroll(function(event){
		didScroll = true;
	});

	setInterval(function() {
		if (didScroll) {
			hasScrolled();
			didScroll = false;
		}
	}, 250);

	function hasScrolled() {
		var st = $(this).scrollTop();
		// Make sure they scroll more than delta
		if(Math.abs(lastScrollTop - st) <= delta) return;
		// If they scrolled down and are past the navbar, add class .nav-up.
		// This is necessary so you never see what is "behind" the navbar.
		if (st > lastScrollTop && st > navbarHeight){
			// Scroll Down
			$('#header').removeClass('fixed').addClass('nofixed');
		} else if (st <= 100){
			$('#header').removeClass('fixed').removeClass('nofixed');
		} else {
			// Scroll Up
			if(st + $(window).height() < $(document).height()) {
				$('#header').removeClass('nofixed').addClass('fixed');
			}
		}
		lastScrollTop = st;
	}
//GNB fixed





$(window).load(function(){
	// 왼쪽메뉴열기_모바일
	$("body").on("click ", ".btnMenu_m", function(){
		$("#menuArea").addClass('visible');
		$(".btnMenu_mClose").fadeIn(300);
		$("body").append("<div id='grayLayer'><a href='#'></a></div>");
		$("#grayLayer").show();

	});

	// 왼쪽메뉴닫기_모바일
	$("body").on("click ", ".btnMenu_mClose", function(){
		$("#menuArea").removeClass('visible');
		$(".btnMenu_mClose").fadeOut(300);
		$("#grayLayer").remove();
	});

	// wrap클릭시 메뉴닫기
	$("body").on("click ", "#grayLayer a", function(){
		$("#menuArea").removeClass('visible');
		$(".btnMenu_mClose").fadeOut(300);
		$("#grayLayer").remove();
	});

	// 왼쪽 하위 메뉴
	$("body").on("click ", "#menuArea .menuList>.list>li", function(){
		var idx = $("#menuArea .menuList>.list>li").index($(this));
		$("#menuArea .menuList>.list>li").each(function(index){
			if(idx == index){
				if(!$(this).hasClass("active")){
					$(this).addClass("active pointColor");
					$(this).find(".sMenu").slideDown(300);
				}else{
					$(this).removeClass("active pointColor");
					$(this).find(".sMenu").slideUp(300);
				}
			}else{
				$(this).removeClass("active pointColor");
				$(this).find(".sMenu").slideUp(300);
			}
		});
	});
});







//메뉴 height값 통일
$(document).ready(function() {
    var max_h = 0;
    $("#gnb .depHeight .depth").each(function() {
      var h = parseInt($(this).css("height"));
      if (max_h < h) {
        max_h = h;
      }
    });
    $("#gnb .depHeight .depth").each(function() {
      $(this).css({
        height: max_h
      });
    });
  });

/*메인메뉴 gnb*/
$(function(){
	$("#gnb .dep_tit").mouseover(function(){
		$(this).addClass("on");
		$(this).children("a").addClass("pointColor");
	}).mouseleave(function(){
		$(this).removeClass("on");
		$(this).children('a').removeClass("pointColor");
	});


	$("#gnb .depth li").mouseover(function(){
		$(this).addClass("pointColor");
		if($(this).find('ul').hasClass('two_depth') === true){
			 $(this).addClass('view');
		} else {
			$(this).removeClass('view');
		}
	}).mouseleave(function(){
		$(this).removeClass("view");
		$(this).removeClass("pointColor");
	});

	$("#gnb .depth li .two_depth li").mouseover(function(){
		if($(this).find('ul').hasClass('three_depth') === true){
			$(this).addClass('view');
		} else {
			$(this).removeClass('view');
		}
	}).mouseleave(function(){
		$(this).removeClass("view");
		$(this).removeClass("pointColor");
	});


});



//top버튼
$(function(){
    $(window).scroll(function(){
      if( $(this).scrollTop()>0){
          $(".quick").fadeIn();
      }else{
          $(".quick").fadeOut();
      }
    });

    $(".topBtn").click(function(){
        $('html,body').animate({'scrollTop':0},500,'easeInCubic');
    });
});


/*메인메뉴 gnb*/
$(function(){
	$(".lnb_cont li a").mouseover(function(){
		$(this).addClass("pointColor");
	}).mouseleave(function(){
		$(this).removeClass("pointColor");
	});
});



$(document).ready(function(){
	/* 2022-11-23 Malgn 메인페이지 별표시 스크립트 서순 이슈로 이동*/
	/*$('.review_list.rolling').slick({
		dots: false, // 도트네비
		arrows: true,
		autoplay: true, // 자동 슬라이드
		speed: 1000,
		slidesToShow: 3,
		autoplaySpeed: 5000, // 슬라이드 속도
		zIndex:50,
		pauseOnFocus:false,
		pauseOnHover:false,
		swipe: true,
		responsive: [
		{
		  breakpoint: 680,
		  settings: {
			slidesToShow: 2,
			slidesToScroll: 1
		  }
		}
	  ]
	});

	$(".review_cont").mCustomScrollbar({
		axis:"y"
	});*/
});
