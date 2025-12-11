
// 메인비주얼
$(document).ready(function(){
  $('.sub_imgbox').slick({
		dots: true, // 도트네비
		arrows: true,
		autoplay: true, // 자동 슬라이드
		speed: 1000,
		autoplaySpeed: 5000, // 슬라이드 속도
		zIndex:50,
		pauseOnFocus:false,
		pauseOnHover:false,
		swipe: true,
		customPaging : function(slider, i) {
			if($('.sub_imgbox').hasClass('dot_custom')){
				var title = $(slider.$slides[i].innerHTML).find('h2[data-title]').data('title');
				return '<a>' + title + '</a>';
			}else{

			}
		}
	});
});




$(document).ready(function(){
  $('.best_list').slick({
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
		  breakpoint: 1024,
		  settings: {
			slidesToShow: 2,
			slidesToScroll: 1,
		  }
		},
		{
		  breakpoint: 680,
		  settings: {
			slidesToShow: 1,
			slidesToScroll: 1
		  }
		}
	  ]
	});
	$('.best_list').show();

	$('.banner').slick({
		dots: true, // 도트네비
		arrows: false,
		autoplay: true, // 자동 슬라이드
		speed: 1000,
		slidesToShow: 1,
		autoplaySpeed: 5000, // 슬라이드 속도
		zIndex:50,
		pauseOnFocus:false,
		pauseOnHover:false,
		swipe: true
	});

	$('.teacher_list').slick({
		dots: false, // 도트네비
		arrows: true,
		autoplay: true, // 자동 슬라이드
		speed: 1000,
		slidesToShow: 4,
		autoplaySpeed: 5000, // 슬라이드 속도
		zIndex:50,
		pauseOnFocus:false,
		pauseOnHover:false,
		swipe: true,
		responsive: [
		{
		  breakpoint: 980,
		  settings: {
			slidesToShow: 3,
			slidesToScroll: 1,
		  }
		},
		{
		  breakpoint: 680,
		  settings: {
			slidesToShow: 2,
			slidesToScroll: 1
		  }
		}
	  ]
	});
	$('.teacher_list').show();
});


/*
$(document).ready(function(){
	$(".schedule").mCustomScrollbar({
		axis:"y"
	});
});*/
