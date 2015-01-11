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
				$("#goodreads-search-input").removeAttr("readonly")
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
				$("#goodreads-search-input").removeAttr("readonly")
			},
			url: '/books/goodreads/info/' + encodeURIComponent(bookId)
		})
	}

	$("#goodreads-search-input").keypress(function (evt) {
		if(evt.which === 13) {
			evt.preventDefault();

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
						
						$("#goodreads-search-spinner").addClass("invisible");
						$("#goodreads-search-input").removeAttr("readonly")

						buildModalResults(data.results);
					},
					url: "/books/search?query=" + encodeURIComponent(searchText)
				})
			}
		}
	});

	$("#add-book-save-button").click(function (evt) {
		evt.preventDefault();
		
		var title = $("#add-book-title").val(),
			author = $("#add-book-author").val(),
			imageUrl = $("#add-book-image-url").val(),
			externalUrl = $("#add-book-external-url").val(),
			summary = $("#add-book-summary").val();

		function validate() {
			var valid = true, parser; 

			$("#add-book-title-group").removeClass("has-error");
			$("#add-book-author-group").removeClass("has-error");
			$("#add-book-image-url-group").removeClass("has-error");
			$("#add-book-external-url-group").removeClass("has-error");
			$("#add-book-summary-group").removeClass("has-error");

			if (!title) {
				valid = false;
				$("#add-book-title-group").addClass("has-error");
			}
			if (!author) {
				valid = false;
				$("#add-book-author-group").addClass("has-error");	
			}

			return valid;
		}

		if (validate()) {
			$("#add-book-title").attr("readonly", true)
			$("#add-book-author").attr("readonly", true)
			$("#add-book-image-url").attr("readonly", true)
			$("#add-book-external-url").attr("readonly", true)
			$("#add-book-summary").attr("readonly", true)
			$("#goodreads-search-input").attr("readonly", true)
			$("#goodreads-search-spinner").removeClass("invisible");

			$.ajax({
				type: 'POST',
				url: "/books/add",
				data: {
					title: title,
					author: author,
					image_url: imageUrl,
					external_url: externalUrl,
					summary: summary
				},
				error: function (jqXHR, textStatus, errorThrown) {
					$("#add-book-title").removeAttr("readonly");
					$("#add-book-author").removeAttr("readonly");
					$("#add-book-image-url").removeAttr("readonly");
					$("#add-book-external-url").removeAttr("readonly");
					$("#add-book-summary").removeAttr("readonly");
					$("#goodreads-search-input").removeAttr("readonly");
					$("#goodreads-search-spinner").addClass("invisible");

					if (jqXHR.status && jqXHR.status == 400 && jqXHR.responseText) {
						jsonData = null; 
						try {
							jsonData = $.parseJSON(jqXHR.responseText);
						} catch (e) {}

						if (jsonData) {
							if (jsonData.field) {
								switch(jsonData.field) {
								case "title":
									$("#add-book-title-group").addClass("has-error");
									break;
								case "author":
									$("#add-book-author-group").addClass("has-error");
									break;
								case "external_url":
									$("#add-book-external-url-group").addClass("has-error");
									break;
								case "image_url":
									$("#add-book-image-url-group").addClass("has-error");
									break;
								case "summary":
									$("#add-book-summary-group").addClass("has-error");
									break;
								}
							}
							alert("The server reported a validation error: " + jsonData.message);
						}
						else {
							alert("The server reported an error: " + jqXHR.responseText);	
						}
					}
					else {
						alert("There was an unknown error while saving. The server returned: " + errorThrown)	
					}
				},
				success: function(data) {
					//either redirect to the book url or the main url. Right now, we don't have a working book url so do the other thing. 
					//or data.book_url when it works
					window.location.href = data.redirect_url
				}
			})
		}
	})
});