$(document).ready(function () {
	var deleteButton = $("#delete-book-button"),
		editButton = $("#edit-book-button"),
		bookEl = $("#book-container"),
		bookId = bookEl.data("book-id");

	deleteButton.click(function () {
		editButton.prop('disabled', true);
		deleteButton.prop('disabled', true);

		bootbox.dialog({
			title: "Delete Book",
			message: "Are you sure you want to delete this book? This cannot be undone.",
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						editButton.prop('disabled', false);
						deleteButton.prop('disabled', false);
					}
				},
				del: {
					label: "Delete",
					className: "btn btn-danger",
					callback: function () {
						$("#page-spinner").removeClass("invisible");
						
						$.ajax({
							url: "/books/book/" + bookId,
							type: "delete",
							success: function (data) { 
								window.location = "/";
							},
							error: function (jqXHR, textStatus, errorThrown) {
								bbBookClub.Utils.showXhrError(jqXHR, "Unable to Delete")
									.then(function () {
										editButton.prop('disabled', false);
										deleteButton.prop('disabled', false);

										$("#page-spinner").addClass("invisible");
									});
							}
						});
					}
				}
			}
		});
	});
});