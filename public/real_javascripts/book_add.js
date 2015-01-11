$(document).ready(function () {
	function buildModalResults(results) {
		var e = $('<div class="container" id="search-results">' + 
						'<div id="search-results-close-container"><a id="search-results-close-button" href="#">Close</a></div>' + 
					'</div>'), 
			i, r, listing;

			for(i = 0; i < results.length; i++) {
				r = results[i];

				listing = $('<div class="row search-listing">' + 
								'<div class="col-sm-2"><img src="' + r["image_thumbnail"] + '"/></div>' + 
								'<div class="col-sm-8">' + 
									'<div class="row"><div class="col-xs-12 search-title">' + r.title + '</div></div>' +
									'<div class="row"><div class="col-xs-12 search-author">' + r.author + '</div></div>' +
								'</div>' +
								'<div class="col-sm-2">' +
									'<div class="row"><div class="col-xs-12">&nbsp;</div></div>' + //spacer
									'<div class="row"><div class="col-xs-12">' + 
										'<button class="search-select-button" ' + 
											'data-title="' + r.title + '" ' +
											'data-author="' + r.author + '" ' + 
											'data-id="' + r.id + '" ' + 
											'data-image="' + r.image + '">Select</button>' +
									'</div></div>' + 
								'</div>' +
							'</div>');


				e.append(listing);
			}

		$("body").append(e)

		$("#search-results-close-button").click(function (evt) {
			evt.preventDefault();
			e.remove();
		});

		$(".search-select-button").click(function (evt) {
			evt.preventDefault();

			var button = $(this),
				title = button.data("title"),
				author = button.data("author"),
				id = button.data("id"),
				image = button.data("image"),
				goodreadsUrl = "https://www.goodreads.com/book/show/" + id;

			$("#add-book-title").val(title);
			$("#add-book-author").val(author);
			$("#add-book-image-url").val(image);
			$("#add-book-external-url").val(goodreadsUrl);

			e.remove();

			$("#summary-spinner").removeClass("invisible");
			$("#add-book-summary").attr("readonly", true)

			$.ajax({
				async: true,
				dataType: 'json',
				error: function (jqXHR, textStatus, errorThrown) {
					$("#add-book-summary").removeAttr("readonly");
					$("#summary-spinner").addClass("invisible");
				},
				success: function (data) {
					var summary = data["description"];
					$("#add-book-summary").val(summary);
					$("#add-book-summary").removeAttr("readonly");
					$("#summary-spinner").addClass("invisible");
				},
				url: '/books/goodreads/info/' + encodeURIComponent(id)
			})
		});

		return e;
	}

	function loadGoodreadsResultsForBook(bookId) {
		$("#add-book-title").attr("readonly", true)
		$("#add-book-author").attr("readonly", true)
		$("#add-book-image-url").attr("readonly", true)
		$("#add-book-external-url").attr("readonly", true)
		$("#add-book-summary").attr("readonly", true)

		$.ajax({
			async: true,
			dataType: 'json',
			error: function (jqXHR, textStatus, errorThrown) {
				$("#add-book-title").removeAttr("readonly")
				$("#add-book-author").removeAttr("readonly")
				$("#add-book-image-url").removeAttr("readonly")
				$("#add-book-external-url").removeAttr("readonly")
				$("#add-book-summary").removeAttr("readonly")
				$("#goodreads-search-spinner").addClass("invisible");
			},
			success: function (data) { 
				$("#add-book-title").val(data.title);
				$("#add-book-author").val(data.author);
				$("#add-book-image-url").val(data.image);
				$("#add-book-external-url").val(data.url);
				$("#add-book-summary").val(data.description);

				$("#add-book-title").removeAttr("readonly")
				$("#add-book-author").removeAttr("readonly")
				$("#add-book-image-url").removeAttr("readonly")
				$("#add-book-external-url").removeAttr("readonly")
				$("#add-book-summary").removeAttr("readonly")
				$("#goodreads-search-spinner").addClass("invisible");
			},
			url: '/books/goodreads/info/' + encodeURIComponent(bookId)
		})
	}

	$("#goodreads-search-input").keypress(function (evt) {
		if(event.which === 13) {
			event.preventDefault();

			$("#goodreads-search-spinner").removeClass("invisible");
			$("#goodreads-search-input").attr("readonly", true)

			$("#goodreads-search-input").blur();

			var searchText = $(this).val(),
				goodreadsRegex = /https?:\/\/(?:www)?.goodreads.com\/book\/show\/(\d+)/,
				regexMatch = goodreadsRegex.exec(searchText),
				goodreadsId;

			if (regexMatch && regexMatch.length > 1) {
				goodreadsId = regexMatch[1];
				loadGoodreadsResultsForBook(goodreadsId);
			}
			else {
				$.ajax({
					async: true,
					dataType: 'json',
					error: function (jqXHR, textStatus, errorThrown) {
						$("#goodreads-search-spinner").addClass("invisible");
						$("#goodreads-search-input").removeAttr("readonly")
					},
					success: function (data) {
						console.log(data);
						
						$("#goodreads-search-spinner").addClass("invisible");
						$("#goodreads-search-input").removeAttr("readonly")

						buildModalResults(data.results);
					},
					url: "/books/search?query=" + encodeURIComponent(searchText)
				})
			}
		}
	});
});