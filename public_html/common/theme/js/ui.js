$(document).ready(function(e) {
	var checkBrowser = function() {
		var agt = navigator.userAgent.toLowerCase();
		if (agt.indexOf("chrome") != -1) return 'Chrome'; 
		if (agt.indexOf("opera") != -1) return 'Opera'; 
		if (agt.indexOf("staroffice") != -1) return 'Star Office'; 
		if (agt.indexOf("webtv") != -1) return 'WebTV'; 
		if (agt.indexOf("beonex") != -1) return 'Beonex'; 
		if (agt.indexOf("chimera") != -1) return 'Chimera'; 
		if (agt.indexOf("netpositive") != -1) return 'NetPositive'; 
		if (agt.indexOf("phoenix") != -1) return 'Phoenix'; 
		if (agt.indexOf("firefox") != -1) return 'Firefox'; 
		if (agt.indexOf("safari") != -1) return 'Safari'; 
		if (agt.indexOf("skipstone") != -1) return 'SkipStone'; 
		if (agt.indexOf("msie") != -1) return 'Internet Explorer'; 
		if (agt.indexOf("netscape") != -1) return 'Netscape'; 
		if (agt.indexOf("mozilla/5.0") != -1) return 'Mozilla'; 
	}

	function onCheckDevice() {
		var isMoble = (/(iphone|ipod|ipad|android|blackberry|windows ce|palm|symbian)/i.test(navigator.userAgent)) ? "mobile" : "pc";
		$("body").addClass(isMoble);

		var deviceAgent = navigator.userAgent.toLowerCase();
		var agentIndex = deviceAgent.indexOf('android');

		if(agentIndex != -1) {
			var androidversion = parseFloat(deviceAgent.match(/android\s+([\d\.]+)/)[1]);

			$("body").addClass("android");

			// favicon();

			if(androidversion < 4.1) {
				$("body").addClass("android_old android_ics");
			}
			else if(androidversion < 4.3) {
				$("body").addClass("android_old android_oldjb");
			}
			else if(androidversion < 4.4) {
				$("body").addClass("android_old android_jb");
			}
			else if(androidversion < 5) {
				$("body").addClass("android_old android_kk");
			}
			else if(androidversion < 6) {
				$("body").addClass("android_old");
			}
			
			if(checkBrowser() == 'Firefox' 
				|| checkBrowser() == 'Mozilla') {
				$("body").removeClass("android_ics android_oldjb android_jb android_kk");
			}
			else if(checkBrowser() == "Chrome") {
				var chromeVersion = parseInt(deviceAgent.substring(deviceAgent.indexOf("chrome") + ("chrome").length + 1));
				
				if(chromeVersion > 40) {
					$("body").removeClass("android_old android_ics android_oldjb android_jb android_kk");
				}
				else {
					$("body").removeClass("android_ics android_oldjb android_jb android_kk");
				}
			}
		}
		else if(deviceAgent.match(/msie 8/) != null || deviceAgent.match(/msie 7/) != null) {
			$("body").addClass("old_ie");
		}
		else if(deviceAgent.match(/iphone|ipod|ipad/) != null) {
			$("body").addClass("ios");
		}
	}

	onCheckDevice();

	// css check
	window.checkSupported = function(property) {
		return property in document.body.style;
	}

	
	// dropdown list
	var dropList = (function() {
		function init() {
			var time = 150;

			// dropdown list
			$(document).on("change", ".dropLst .hidradio", function(evt) {
				var groupName = $(this).attr("name");
				var radios = $(".hidradio[name=" + groupName + "]");
				var checked = radios.filter(function() { return $(this).prop("checked") === true; });
				var text = $(checked).parents("label").find(".value").text();
				var list = $(checked).parents(".dlst").eq(0);

				$(list).find("label").removeClass("on");
				$(checked).parents("label").eq(0).addClass("on");

				if($(list).siblings(".txt").find(".val").length > 0) {
					$(list).siblings(".txt").find(".val").text(text);
				}
				else {
					$(list).siblings(".txt").text(text);
				}

				$(list).siblings(".txt").removeClass("on");
				$(checked).parents(".dlst").slideUp(time);
			}).on("click", ".dropLst > a", function(evt) {
				evt.preventDefault();
				
				var label = $(this);
				var target = $(this).parents(".dropLst").eq(0);
				var list = $(this).siblings(".dlst");
				var openList = $(".dropLst").filter(function() { return $(this).find(".dlst").css("display") != "none" && $(this) != target });

				$(openList).find(".dlst").stop().slideUp(time);
				$(target).find(" > a").removeClass("on").addClass("active");

				$(list).stop().slideToggle(time, function() {
					if($(this).css("display") != "none") $(label).addClass("on");
					else $(label).removeClass("on");

					$(label).removeClass("active");
				});
			}).on("click", ".dropLst li a", function(evt) {
				var value = $(this).text();

				$(this).parents(".dlst").eq(0).stop().slideUp(time, function() {
					if($(this).siblings(".txt").find(".val").length > 0) {
						$(this).siblings(".txt").find(".val").text(value);
					}
					else {
						$(this).siblings(".txt").text(value);
					}

					$(this).siblings(".txt").focus();
				});

				$(".dropLst > a").removeClass("on");

				$(this).parents(".dlst").eq(0).find("li a").removeClass("on");
				$(this).addClass("on");
			}).on("keyup", ".dropLst > a", function(evt) {
				var keyCode = evt.keyCode;

				var target = $(this).parents(".dropLst").eq(0);
				var list = $(this).siblings(".dlst");
				var chkRadio = $(this).siblings(".dlst").find(".hidradio:checked");
				var hoverRadio = $(list).find(".hover");
				var idx = -1;

				if(hoverRadio.length < 1) idx = (chkRadio.parents("li").eq(0).index() > -1) ? chkRadio.parents("li").eq(0).index() : 0;
				else idx = hoverRadio.parents("li").eq(0).index();

				var openList = $(list).filter(function() { return $(this).css("display") != "none" });
				if(openList.length < 1) return false;

				if(keyCode == 13) {
					$(list).find("li").find(".hover").find(".hidradio").prop("checked", true).trigger("change");
					$(list).find("label").removeClass("hover");
				} 
				else if(keyCode == 38 || keyCode == 37) {
					$(list).find("label").removeClass("hover");

					if(idx == 0) $(list).find("li").eq($(list).find("li").length - 1).find("label").addClass("hover");
					else $(list).find("li").eq(idx - 1).find("label").addClass("hover");
				}
				else if(keyCode == 40 || keyCode == 39) {
					$(list).find("label").removeClass("hover");
					
					if(idx == ($(list).find("li").length - 1)) $(list).find("li").eq(0).find("label").addClass("hover");
					else $(list).find("li").eq(idx + 1).find("label").addClass("hover");
				}
			}).on("focus", ".dropLst .dlst label", function(evt) {
				$(this).on("keyup", addEnterKeyEvent);
			}).on("blur", "label", function(evt) {
				$(this).off("keyup", addEnterKeyEvent);
			}).on("click touchstart", function(evt) {
				var evt = evt ? evt : event;
				var target = null;

				if (evt.srcElement) target = evt.srcElement;
				else if (evt.target) target = evt.target;

				var openList = $(".dropLst").filter(function() { return $(this).find(".dlst").css("display") != "none" });
				var activeList = $(".dropLst").filter(function() { return $(this).find(".txt").hasClass("on") === true });
				if($(target).parents(".dropLst").eq(0).length < 1) {
					$(openList).find(".dlst").slideUp(time);
					$(".dropLst > a").removeClass("on").removeClass("active");
				}
				else if(activeList.length > 0) {
					if(evt.type == "click") {
						activeList.find(".txt").removeClass("on").removeClass("active");
					}
				}
			});

			function addEnterKeyEvent(evt) {
				var keyCode = evt.keyCode;
				if(keyCode == 13) {
					$(this).children(".hidradio").prop("checked", true).trigger("change");
					$(this).parents(".dropLst").eq(0).find(".txt").focus();
				}
			}

			// init dropdown list value
			$(".dropLst").each(function(i) {
				var groupName = $(this).find(".hidradio").eq(0).attr("name");
				var radios = $(".hidradio[name=" + groupName + "]");
				var checked = $(radios).filter(function() { return $(this).prop("checked") === true; });
				var list = $(this).find(".dlst");
				var text = null;

				if(radios.length > 0 && checked.length > 0) {
					text = (checked.length > 0) ? $(checked).parents("label").find(".value").text() : radios.eq(0).siblings(".value").text();
	
					$(list).find("label").removeClass("on").attr("tabindex", 0);
					$(list).find("label input").attr("tabindex", -1);
					if (checked.length > 0) {
						$(checked).parents("label").eq(0).addClass("on");
					}
					else {
						radios.eq(0).parents("label").eq(0).addClass("on");
					}
				}
				else {
					text = (list.find(".value.on").length > 0) ? list.find(".value.on").text() : (($(this).find(".txt .val").length > 0) ? $(this).find(".txt .val").text() : $(this).find(".txt").text());
				}				

				if($(list).siblings(".txt").find(".val").length > 0) {
					$(list).siblings(".txt").find(".val").text(text);
				}
				else {
					$(list).siblings(".txt").text(text);
				}
			});
		}

		return {
			init : init
		};
	}());

	dropList.init();

});


//셀렉트박스
$(document).ready(function(){
	const label = document.querySelectorAll('.label');
	label.forEach(function(lb){
		lb.addEventListener('click', e => {
			let optionList = lb.nextElementSibling;
			let optionItems = optionList.querySelectorAll('.optionItem');
			clickLabel(lb, optionItems);
		})
	});
	const clickLabel = (lb, optionItems) => {
		if(lb.parentNode.classList.contains('active')) {
			lb.parentNode.classList.remove('active');
			optionItems.forEach((opt) => {
				opt.removeEventListener('click', () => {
					handleSelect(lb, opt)
				})
			})
		} else {
			lb.parentNode.classList.add('active');
			optionItems.forEach((opt) => {
				opt.addEventListener('click', () => {
					handleSelect(lb, opt)
				})
			})
		}
	}
	const handleSelect = (label, item) => {
		label.innerHTML = item.textContent;
		label.parentNode.classList.remove('active');
	}
});