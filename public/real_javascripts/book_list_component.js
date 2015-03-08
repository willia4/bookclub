//This is defined as a jQuery plugin for convenience. However, it works hand-in-hand with the _book_list_template partial erb (not to mention the CSS...(
//and is not self-supporting.

(function ($) {
	$.fn.book_list = function (options) {
		var settings = $.extend({}, $.fn.book_list.defaults, options);
		if (!settings.getUrl) {
			throw "Caller must specify url to GET books from"
		}

		var parent = this;

		if(settings.showSpinnerCallback) {
			settings.showSpinnerCallback.apply(parent);
		}

		var template = $("#" + settings.templateId).text();
		template = Handlebars.compile(template);

		$.ajax({
			url: settings.getUrl,
			type: "GET",
			dataType: "json",
			success: function (books) {
				var data = {}
				data[settings.collectionName] = books;

				var html = template(data);
				parent.html(html);

				if(settings.hideSpinnerCallback) {
					settings.hideSpinnerCallback(parent);
				}
			},
			error: function (xhr, status, errorThrown) {
				if(settings.hideSpinnerCallback) {
					settings.hideSpinnerCallback(parent);
				}

				throw errorThrown;
			}
		})

		return parent;
	};

	$.fn.book_list.defaults = {
		getUrl: null,
		showSpinnerCallback: null,
		hideSpinnerCallback: null,
		templateId: "book-list-template",
		collectionName: "books"
	};
})(jQuery);