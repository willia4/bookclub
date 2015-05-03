$(document).ready(function () {
	var editButton = $("#edit-meeting-button"),
		deleteButton = $("#delete-meeting-button"),
		meetingEl = $("#meeting-container");

	function hasSelectedBook() {
		return !!meetingEl.data("meetingSelectedBookId");
	}

	deleteButton.click(function (evt) {
		editButton.prop('disabled', true);
		deleteButton.prop('disabled', true);

		var message = !hasSelectedBook() ? "Really delete this meeting and all of its nominations and votes? This cannot be undone."
										 : "This meeting has already been voted on. Really delete it? This cannot be undone.";

		bootbox.dialog({
			title: "Delete Meeting",
			message: message,
			buttons: {
				no: {
					label: "No",
					className: "btn btn-primary",
					callback: function () {
						//The box will close itself
						editButton.prop('disabled', false);
						deleteButton.prop('disabled', false);
					}
				},
				del: {
					label: "Delete",
					className: "btn btn-danger",
					callback: function () {
						var meetingId = meetingEl.data("meeting-id"),
							url = "/meetings/meeting/" + meetingId;

						$("#page-spinner").removeClass("invisible");

						$.ajax({
							url: url,
							type: 'delete',
							success: function () {
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