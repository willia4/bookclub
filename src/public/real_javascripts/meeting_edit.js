$(document).ready(function () {
	var today = Date.today,
		editButton = $("#edit-meeting-button"),
		saveButton = $("#edit-meeting-save-button"),
		cancelButton = $("#edit-meeting-cancel-button"),
		deleteButton = $("#delete-meeting-button"),

		meetingEl = $("#meeting-container"),

		meetingDateEl = $("#meeting-date"),
		meetingDateFormEl = null,

		meetingTimeEl = $("#meeting-time"),
		meetingTimeFormEl = null,

		meetingLocationEl = $("#meeting-location"),
		meetingLocationFormEl = null,

		meetingId,
		originalValues = {},
		votingOverlayEl = $('<div class="overlay"></div>');

	function disableVoting() {
		$(".book-list").append(votingOverlayEl);
		setTimeout(function () {
			votingOverlayEl.addClass("on");
		}, 0);
	}

	function enableVoting() {
		votingOverlayEl.removeClass("on");
		setTimeout(function () {
			votingOverlayEl.remove();
		}, 500);
	}

	function createFormElements() {
		meetingDateFormEl = $('<input class="form-control" id="edit-meeting-date" placeholder="Date" type="text"/>');
		meetingDateEl.replaceWith(meetingDateFormEl);

		meetingDateFormEl.val(originalValues.date);
		meetingDateFormEl.datepicker(
			{
				format: "mm/dd/yyyy",
				onRender: function(date) {
					return '';
					// return date < today ? 'disabled' : '';
				}
			});

		meetingTimeFormEl = $('<input class="form-control" id="edit-meeting-time" placeholder="Time" type="text"/>');
		meetingTimeFormEl.val(originalValues.time);
		meetingTimeEl.replaceWith(meetingTimeFormEl);

		//If the un-edited meeting doesn't have a time, we don't draw the "@" between the date and time. But it looks better in form-view with it
		//So add it back if necessary 
		if(!originalValues.time) {
			$("#meeting-time-symbol").html("@ ");
		}

		meetingLocationFormEl = $('<input class="form-control" id="edit-meeting-location" placeholder="Location" type="text"/>');
		meetingLocationFormEl.val(originalValues.location);
		meetingLocationEl.replaceWith(meetingLocationFormEl);

		deleteButton.prop('disabled', true);
	}

	function removeFormElements() {
		clearErrors();

		meetingDateFormEl.replaceWith(meetingDateEl);
		meetingTimeFormEl.replaceWith(meetingTimeEl);
		meetingLocationFormEl.replaceWith(meetingLocationEl);

		//If the un-edited meeting doesn't have a time, we added the "@" between the date and time form elements. But now we need to get rid of it 
		//again
		if(!originalValues.time) {
			$("#meeting-time-symbol").html("");
		}

		meetingDateFormEl = null;
		meetingTimeFormEl = null;
		meetingLocationFormEl = null;

		deleteButton.prop('disabled', false);
	}

	function enableFormElements() {
		meetingDateFormEl.attr("readonly", false);
		meetingTimeFormEl.attr("readonly", false);
		meetingLocationFormEl.attr("readonly", false);

		saveButton.prop("disabled", false);
		cancelButton.prop("disabled", false);
	}

	function disableFormElements() {
		meetingDateFormEl.attr("readonly", true);
		meetingTimeFormEl.attr("readonly", true);
		meetingLocationFormEl.attr("readonly", true);

		saveButton.prop("disabled", true);
		cancelButton.prop("disabled", true);
	}

	function addErrorAlert(message)
	{
		var e = $('<div class="alert alert-danger">' + message + '</div>');
		$("#validation-errors").append(e);
	}

	function errorForControl(jqControl, message, isError) {
		//if isError isn't passed in, assume that we want an error
		if (typeof isError === "undefined") {
			isError = true;
		}

		if (isError) {
			jqControl.parent().addClass("has-error");
			addErrorAlert(message);
		}

		return !isError;
	}

	function clearErrors() {
		$("#validation-errors").html('');
		meetingDateFormEl.parent().removeClass("has-error");
		meetingTimeFormEl.parent().removeClass("has-error");
		meetingLocationEl.parent().removeClass("has-error");
	}

	editButton.click(function () {
		$("#page-spinner").addClass("invisible");
		disableVoting();
		createFormElements();

		editButton.addClass("hidden");
		cancelButton.removeClass("hidden");
		saveButton.removeClass("hidden");
	});

	cancelButton.click(function () {
		$("#page-spinner").addClass("invisible");
		enableVoting();
		removeFormElements();

		editButton.removeClass("hidden");
		cancelButton.addClass("hidden");
		saveButton.addClass("hidden");
	});

	saveButton.click(function () {
		var meetingDate = Date.parse(meetingDateFormEl.val()),
			meetingTime = meetingTimeFormEl.val(),
			meetingLocation = meetingLocationFormEl.val();

		function validate() {
			var valid = true;
			
			clearErrors();
			valid = errorForControl(meetingDateFormEl, "Date is required", !meetingDate) && valid;

			return valid;
		}
		
		if(validate()) {
			$("#page-spinner").removeClass("invisible");
			disableFormElements();

			$.ajax({
				url: '/meetings/meeting/' + meetingId + '/edit',
				type: 'POST',
				data: {
					meeting_date: meetingDate,
					meeting_time: meetingTime,
					meeting_location: meetingLocation
				},
				error: function (jqXHR, textStatus, errorThrown) {
					var jsonData = null;
					
					enableFormElements();
					$("#page-spinner").addClass("invisible");

					if (jqXHR && jqXHR.status == 400 && jqXHR.responseText) {
						try {
							jsonData = $.parseJSON(jqXHR.responseText)
						} catch (e) {}

						if (jsonData && jsonData.message) {
							if(jsonData.field) {
								switch(jsonData.field) {
								case "meeting_date":
									errorForControl(meetingDateFormEl, jsonData.message, true);
									break;
								case "meeting_time":
									errorForControl(meetingTimeFormEl, jsonData.message, true);
									break;
								case "meeting_location":
									errorForControl(meetingLocationFormEl, jsonData.message, true);
									break;
								}
							} 
							else {
								addErrorAlert("The server reported a validation issue: " + jsonData.message);
							}
						}
						else {
							addErrorAlert("The server reported an error: " + jqXHR.responseText);
						}
					}
					else {
						addErrorAlert("There was an unknown error while saving. The server returned: " + errorThrown);
					}
				},
				success: function () {
					window.location.reload();
				}
			})
		}
	});

	meetingId = meetingEl.data("meeting-id");
	originalValues.date = meetingEl.data("meeting-date");
	originalValues.time = meetingEl.data("meeting-time");
	originalValues.location = meetingEl.data("meeting-location");
});