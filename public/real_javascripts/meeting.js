$(document).ready(function () {
	var meetingId = $("#meeting-container").data("meeting-id"),
		selectedBookId = $("#meeting-container").data("selected-book-id"),
		template;

	template = $("#book-nominations-template").text();
	template = Handlebars.compile(template);

	function loadBooksHtml(callback) {
		var url = "/meetings/meeting/" + meetingId + "/books";
		$("#page-spinner").removeClass("invisible");

		$.ajax({
			url: url,
			error: function () {
				$("#page-spinner").addClass("invisible");
			},
			success: function (data) {
				$("#page-spinner").addClass("invisible");

				if (callback) {
					callback(template(data));
				}
			}
		})
	}

	function startVote(bookId, direction) {
		var url;

		$(".vote-up-button").off("click");
		$(".vote-down-button").off("click");
		$("#page-spinner").removeClass("invisible");

		url = '/meetings/meeting/' + meetingId + '/books/' + bookId + '/vote/' + direction
		$.ajax({
			type: 'POST',
			url: url,
			error: function (jqXHR, textStatus, errorThrown) {
			},
			success: function (data) {
				var shadow = $('<ul class="book-list"></ul>'),
					real = $("ul.book-list"),
					shadowHtml = template(data);

				shadow.html(shadowHtml);

				real.quicksand(shadow.find("li"), {
					adjustWidth: false,
					easing: 'easeInOutQuad',
					retainExisting: false
				}, function () {
					$("#page-spinner").addClass("invisible");

					$(".vote-up-button:not(.vote-selected)").on("click", voteUpHandler);
					$(".vote-down-button:not(.vote-selected)").on("click", voteDownHandler);
				});				
			}
		});
	}

	function voteUpHandler(event) {
		var t = $(this),
			bookId = t.data("id"),
			bookElement = $('.book-listing[data-id="' + bookId + '"]');
		
		startVote(bookId, "up");
	}

	function voteDownHandler(event) {
		var t = $(this),
			bookId = t.data("id"),
			bookElement = $('.book-listing[data-id="' + bookId + '"]');
		
		startVote(bookId, "down");
	}

	if(!selectedBookId) {
		html = template(window.bbBookClub.initialState);
		$("ul.book-list").html(html);
		$(".vote-up-button:not(.vote-selected)").on("click", voteUpHandler);
		$(".vote-down-button:not(.vote-selected)").on("click", voteDownHandler);
	}
});