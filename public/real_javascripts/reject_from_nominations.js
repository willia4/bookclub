window.bbBookClub = window.bbBookClub || {};

//args.isAdmin
//args.userId
//args.bookListJQueryElement
//args.showSpinnerCallback
//args.hideSpinnerCallback
window.bbBookClub.setupBookListForRejectionFromNomination = function (args) {
	function rejectHandler(bookId, title, completionCallback) {
		var t = this;

		bootbox.dialog({
			title: "Reject \"" + title + "\"",
			message: "This will reject the book from further consideration by the group. If desired, it can be un-rejected at a later date on the Books page.",
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						//The box will close on its own
						completionCallback();
					}
				},
				reject: {
					label: "Reject",
					className: "btn btn-danger",
					callback: function () {
						var url = "/books/book/" + bookId + "/reject";

						$.ajax({
							type: "POST",
							dataType: "json",
							url: url,
							error: function (jqXHR, textStatus, errorThrown) {
								bbBookClub.Utils.showXhrError(jqXHR)
									.then(function () {
										completionCallback();
									});
							},
							success: function (data) {
								t.reloadBooks(data, function () {
									completionCallback();
								});
							}
						});
					}
				}
			}
		});
	}

	args.bookListJQueryElement.bookList({
		getUrl: "/books/unread.json", 
		sort: "desc",
		
		showSpinnerCallback: args.showSpinnerCallback,
		hideSpinnerCallback: args.hideSpinnerCallback,

		buttons: [
			{
				title: "Reject",
				type: "danger",
				callback: rejectHandler,
				shouldShow: function(book) {
					return (args.isAdmin || book.addedby_id == args.userId);
				}
			}
		]
	});
};

//args.isAdmin
//args.userId
//args.bookListJQueryElement
//args.showSpinnerCallback
//args.hideSpinnerCallback
window.bbBookClub.setupBookListForUnrejectionFromNomination = function (args) {
	function unrejectHandler(bookId, title, completionCallback) {
		var t = this;

		bootbox.dialog({
			title: "Un-Reject \"" + title + "\"",
			message: "This will re-add this book to the list of nominations for future consideration by the group.",
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						//this box will close on its own
						completionCallback();
					}
				},
				unreject: {
					label: "Un-Reject",
					className: "btn btn-success",
					callback: function () {
						var url = "/books/book/" + bookId + "/unreject";

						$.ajax({
							type: "POST",
							dataType: "json",
							url: url,
							error: function (jqXHR, textStatus, errorThrown) {
									var messageTitle = jqXHR.getResponseHeader("X-Bookclub-Error-Title") || "Unknown Error",
										messageBody = jqXHR.getResponseHeader("X-Bookclub-Error-Reason") || "An unknown error has occurred";

									bootbox.dialog({
										title: messageTitle,
										message: messageBody,
										buttons: {
											ok: {
												label: "Ok",
												className: "btn btn-primary",
												callback: function () {
													completionCallback();
												}
											}
										}
									});
							},
							success: function (data) {
								t.reloadBooks(data, function () {
									completionCallback();
								});
							}
						});
					}
				}
			}
		});
	}

	args.bookListJQueryElement.bookList({
		getUrl: "/books/rejected.json",
		sort: "asc",
		
		showSpinnerCallback: args.showSpinnerCallback,
		hideSpinnerCallback: args.hideSpinnerCallback,

		buttons: [
			{
				title: "Un-Reject",
				type: "success",
				callback: unrejectHandler,
				shouldShow: function(book) {
					return (args.isAdmin || book.addedby_id == args.userId);
				}
			}
		]
	});
}