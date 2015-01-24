$(document).ready(function () {
	var meetingEl = $("#meeting-container"),
		meetingId = meetingEl.data("meeting-id"),
		i, b, listing;

	function buildModalResults(books) {
		var e = $(	'<div class="container" id="search-results">' + 
						'<div id="search-results-close-container"><a id="search-results-close-button" href="#">Close</a></div>' + 
					'</div>');

		for(i = 0; i < books.length; i++) {
			b = books[i];

			listing = $('<div class="row search-listing">' + 
							'<div class="col-sm-2"><img src="' + b.image_url + '"/></div>' + 
							'<div class="col-sm-8">' + 
								'<div class="row"><div class="col-xs-12 search-title">' + b.title + '</div></div>' +
								'<div class="row"><div class="col-xs-12 search-author">' + b.author + '</div></div>' +
							'</div>' +
							'<div class="col-sm-2">' +
								'<div class="row"><div class="col-xs-12">&nbsp;</div></div>' + //spacer
								'<div class="row"><div class="col-xs-12">' + 
									'<button class="search-select-button btn btn-primary" ' + 
										'data-book-id="' + b.book_id + '">Add</button>' +
								'</div></div>' + 
							'</div>' +
						'</div>');

			e.append(listing);
		}

		$("body").append(e);

		$("#search-results-close-button").click(function (evt) {
			evt.preventDefault();
			e.remove();
		});

		$(".search-select-button").click(function (evt) {
			evt.preventDefault();
			$("#page-spinner").removeClass("invisible");
			e.remove(); 

			var button = $(this),
				bookId = button.data("book-id");

			$.ajax({
				url: '/meetings/meeting/' + meetingId + '/books/' + bookId,
				type: 'PUT',
				data: {},
				error: function (jqXHR, textStatus, errorThrown) {
					$("#page-spinner").addClass("invisible");
					alert("Unable to add book: " + errorThrown);
				},
				success: function (data) {
					window.location.reload();
				}
			})
		});
	}

	$("#add-book-button").click(function () {
		$("#page-spinner").removeClass("invisible");
		$.ajax({
			type: 'GET',
			url: '/meetings/meeting/' + meetingId + '/other_unread',
			error: function (jqXHR, textStatus, errorThrown) {
				$("#page-spinner").addClass("invisible");
				alert("Unable to perform search: " + errorThrown);
			},
			success: function (data) {
				$("#page-spinner").addClass("invisible");
				buildModalResults(data.books);
			}
		})
	});

});