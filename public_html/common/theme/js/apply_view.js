
$(function() {
    $(window).scroll(function() {
		var scrollTop = $(window).scrollTop();
		var btnTop = $('.apply_view').offset().top - $(window).height() + 700;

        if (scrollTop >= btnTop) {
			$(".applyBtn").addClass("fixed");
			return false;
        }else{
			$(".applyBtn").removeClass("fixed");
			return false;
        }
    });
});