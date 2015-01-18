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

	function replaceBooks(newBookData, callback) {
		var shadow = $('<ul class="book-list"></ul>'),
			real = $("ul.book-list"),
			shadowHtml = template(newBookData);

		shadow.html(shadowHtml);

		real.quicksand(shadow.find("li"), {
			adjustWidth: false,
			easing: 'easeInOutQuad',
			retainExisting: false
		}, function () {
			if (callback) {
				callback();
			}
		});	
	}

	function startVote(bookId, direction) {
		var url;

		removeEventHandlers();
		$("#page-spinner").removeClass("invisible");

		url = '/meetings/meeting/' + meetingId + '/books/' + bookId + '/vote/' + direction
		$.ajax({
			type: 'POST',
			url: url,
			error: function (jqXHR, textStatus, errorThrown) {
			},
			success: function (data) {
				replaceBooks(data, function () {
					$("#page-spinner").addClass("invisible");

					addEventHandlers();
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

	function startRejection(bookId) {
		var url;

		removeEventHandlers();
		$("#page-spinner").removeClass("invisible");

		url = "/meetings/meeting/" + meetingId + "/books/" + bookId;
		$.ajax({
			type: 'DELETE',
			dataType: 'json',
			url: url,
			error: function (jqXHR, textStatus, errorThrown) {
				$("#page-spinner").addClass("invisible");
			},
			success: function (data) {
				replaceBooks(data, function () {
					$("#page-spinner").addClass("invisible");

					addEventHandlers();
				});
			}
		});
	}

	function startSelect(bookId) {
		var url;

		removeEventHandlers();
		$("#page-spinner").removeClass("invisible");

		url = "/meetings/meeting/" + meetingId + "/books/" + bookId + "/select";
		$.ajax({
			type: 'GET',
			url: url,
			error: function (jqXHR, textStatus, errorThrown) {
				$("#page-spinner").addClass("invisible");
			},
			success: function (data) {
				document.location.reload(true);
			}
		});
	}

	function rejectHandler(event) {
		var t = $(this);
		bootbox.dialog({
			title: "Reject Book",
			message: "Are you sure you want to reject \"" + t.data("title") + "\" from being considered for this meeting?",
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						//the box will close on its own
					}
				},
				reject: {
					label: "Reject",
					className: "btn btn-danger",
					callback: function () {
						startRejection(t.data("book-id"));
					}
				}
			}
		});
	}

	function selectHandler(event) {
		var t= $(this);
		bootbox.dialog({
			title: "Select Book",
			message: "Are you sure you want to choose \"" + t.data('title') + "\" for this meeting?",
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						//the box will close on its own
					}
				},
				select: {
					label: "Select",
					className: "btn btn-success",
					callback: function () {
						startSelect(t.data("book-id"));
					}
				}
			}
		});
	}

	function addEventHandlers() {
		$(".vote-up-button:not(.vote-selected)").on("click", voteUpHandler);
		$(".vote-down-button:not(.vote-selected)").on("click", voteDownHandler);
		$(".book-reject-button").on("click", rejectHandler);
		$(".book-select-button").on("click", selectHandler);
	}

	function removeEventHandlers() {
		$(".vote-up-button").off("click");
		$(".vote-down-button").off("click");
		$(".book-reject-button").off("click");
		$(".book-select-button").off("click");
	}

	if(!selectedBookId) {
		html = template(window.bbBookClub.initialState);
		$("ul.book-list").html(html);
		addEventHandlers();
	}
});