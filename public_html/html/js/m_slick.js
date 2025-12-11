const currentSlickSelectors = [null, null];
const currentSlicks = [0, 0];
function initSlick(qs, n, v) {
    const arrow_left = $("#mc" + v + "-arrow-left");
    const arrow_right = $("#mc" + v + "-arrow-right")
    if($(qs.selector + " li").length <= 1) {
        arrow_left.removeClass('slick-disabled');
        arrow_left.addClass('slick-disabled');
        arrow_right.removeClass('slick-disabled');
        arrow_right.addClass('slick-disabled');
        return;
    }
    
    currentSlicks[v] = n;
    if(currentSlickSelectors[v] !== qs) currentSlickSelectors[v] = qs;
    currentSlickSelectors[v].slick({
        dots: false,
        infinite: true,
        speed: 500,
        slidesToShow: 4,
        slidesToScroll: 1,
		touchMove:1,
        responsive: [           
            {
                breakpoint: 767,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1
                }
            }
        ],
        prevArrow : arrow_left,
        nextArrow : arrow_right
    });
}

function initSlick1(qs, n, v) {
    const arrow_left = $("#mcb-arrow-left");
    const arrow_right = $("#mcb-arrow-right")
    if($(qs.selector + " li").length <= 1) {
        arrow_left.removeClass('slick-disabled');
        arrow_left.addClass('slick-disabled');
        arrow_right.removeClass('slick-disabled');
        arrow_right.addClass('slick-disabled');
        return;
    }
    
    currentSlicks[v] = n;
    if(currentSlickSelectors[v] !== qs) currentSlickSelectors[v] = qs;
    currentSlickSelectors[v].slick({
        dots: false,
        infinite: true,
        speed: 500,
        slidesToShow: 3,
        slidesToScroll: 1,			
		autoplay:true,
		touchMove:1,
        responsive: [ 
            {
                breakpoint: 767,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1
                }
            },
			{
                breakpoint: 480,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1
                }
            },
        ],
        prevArrow : arrow_left,
        nextArrow : arrow_right
    });
}
function initSlick2(qs, n, v) {
    const arrow_left = $("#mt-arrow-left");
    const arrow_right = $("#mt-arrow-right")
    if($(qs.selector + " li").length <= 1) {
        arrow_left.removeClass('slick-disabled');
        arrow_left.addClass('slick-disabled');
        arrow_right.removeClass('slick-disabled');
        arrow_right.addClass('slick-disabled');
        return;
    }
    
    currentSlicks[v] = n;
    if(currentSlickSelectors[v] !== qs) currentSlickSelectors[v] = qs;
    currentSlickSelectors[v].slick({
        dots: false,
        infinite: true,
        speed: 500,
        slidesToShow: 2,
        slidesToScroll: 1,
		touchMove:1,
        responsive: [
			{
                breakpoint: 680,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1
                }
            }
        ],
        prevArrow : arrow_left,
        nextArrow : arrow_right
    });
}

function initSlick3(qs, n, v) {
    const arrow_left = $("#mp-arrow-left");
    const arrow_right = $("#mp-arrow-right")
    if($(qs.selector + " li").length <= 1) {
        arrow_left.removeClass('slick-disabled');
        arrow_left.addClass('slick-disabled');
        arrow_right.removeClass('slick-disabled');
        arrow_right.addClass('slick-disabled');
        return;
    }
    
    currentSlicks[v] = n;
    if(currentSlickSelectors[v] !== qs) currentSlickSelectors[v] = qs;
    currentSlickSelectors[v].slick({
        dots: false,
        infinite: true,
        speed: 500,
        slidesToShow: 5,
        slidesToScroll: 1,
		touchMove:1,
        responsive: [ 
            {
                breakpoint: 767,
                settings: {
                    slidesToShow: 4,
                    slidesToScroll: 1
                }
            },
			{
                breakpoint: 480,
                settings: {
                    slidesToShow: 3,
                    slidesToScroll: 1
                }
            },
        ],
        prevArrow : arrow_left,
        nextArrow : arrow_right
    });
}
function initSlick4(qs, n, v) {
    const arrow_left = $("#mb-arrow-left");
    const arrow_right = $("#mb-arrow-right")
    if($(qs.selector + " li").length <= 1) {
        arrow_left.removeClass('slick-disabled');
        arrow_left.addClass('slick-disabled');
        arrow_right.removeClass('slick-disabled');
        arrow_right.addClass('slick-disabled');
        return;
    }
    
    currentSlicks[v] = n;
    if(currentSlickSelectors[v] !== qs) currentSlickSelectors[v] = qs;
    currentSlickSelectors[v].slick({
        dots: false,
        infinite: true,
        speed: 500,
        slidesToShow: 5,
        slidesToScroll: 1,
		touchMove:1,
        responsive: [ 
            {
                breakpoint: 767,
                settings: {
                    slidesToShow: 3,
                    slidesToScroll: 1
                }
            },
			{
                breakpoint: 480,
                settings: {
                    slidesToShow: 2,
                    slidesToScroll: 1
                }
            },
        ],
        prevArrow : arrow_left,
        nextArrow : arrow_right
    });
}