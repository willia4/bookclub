//This is defined as a jQuery plugin for convenience. However, it works hand-in-hand with the _book_list_template partial erb (not to mention the CSS...(
//and is not self-supporting.

(function ($) {

	$.fn.book_list = function (options) {
		var settings = $.extend({}, $.fn.book_list.defaults, options), 
			parent = this, 
			template = Handlebars.compile($("#" + settings.templateId).text());

		function renderBooksInParent(books) {
			var data = {};
			if (books.hasOwnProperty(settings.collectionName)) {
				data = books;
			}
			else {
				data[settings.collectionName] = books;
			}

			parent.html(template(data));
		}

		settings = $.extend({}, $.fn.book_list.defaults, options);
		if (!settings.getUrl && !settings.initialState) {
			throw "Caller must specify url to GET books from or provide an initial state"
		}

		if(settings.showSpinnerCallback) {
			settings.showSpinnerCallback.apply(parent);
		}

		template = $("#" + settings.templateId).text();
		template = Handlebars.compile(template);

		if (settings.initialState) {
			renderBooksInParent(settings.initialState);
		}
		else {
			$.ajax({
				url: settings.getUrl,
				type: "GET",
				dataType: "json",
				success: function (books) {
					renderBooksInParent(books);
					
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
			});
		}
		

		return parent;
	};

	$.fn.book_list.defaults = {
		getUrl: null,
		initialState: null,
		showSpinnerCallback: null,
		hideSpinnerCallback: null,
		templateId: "book-list-template",
		collectionName: "books"
	};
})(jQuery);