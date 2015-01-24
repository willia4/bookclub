$(document).ready(function () {
	function makeReadonly() {
		$("form input").attr("readonly", true);
		$("form button").prop("disabled", true);
	}

	function makeEditable() {
		$("form input").removeAttr("readonly");
		$("form button").prop("disabled", false);
	}

	function clearErrorAlerts() {
		$("#validation-errors").html('');
	}

	function removeErrorsFromControls() {
		$(".has-error").removeClass("has-error");
	}

	function addErrorAlert(message) {
		var e = $('<div class="alert alert-danger">' + message + '</div>');
		$("#validation-errors").append(e);
	}

	function errorForControl(jqControl, message, isError) {
		//if isError isn't passed in, assume that we want an error
		if (typeof isError === "undefined") {
			isError = true;
		}

		if (isError) {
			jqControl.addClass("has-error");
			addErrorAlert(message);
		}

		return !isError;
	}


	var today = Date.today(),
		todayString = today.toString("MM/dd/yyyy");
	$("#add-meeting-date").val(todayString);
	$("#add-meeting-date").datepicker(
		{
			format: "mm/dd/yyyy",
			onRender: function(date) {
				// return date < today ? 'disabled' : '';
				return '';
			}
		});
	$("#add-meeting-time").val('5:30ish');

	$("#add-meeting-save-button").click(function (event) {
		event.preventDefault();

		var meetingDate = Date.parse($("#add-meeting-date").val()),
			meetingTime = $("#add-meeting-time").val(),
			meetingLocation = $("#add-meeting-location").val();

		meetingDate = meetingDate ? meetingDate.clearTime() : null;

		function validate() {
			var valid = true;
			
			clearErrorAlerts();
			removeErrorsFromControls();

			valid = errorForControl($("#add-meeting-date-group"), "Date is required", !meetingDate) && valid;
			
			return valid;
		}
		
		if (validate()) {
			makeReadonly();
			$("#page-spinner").removeClass("invisible");

			$.ajax({
				type: 'POST',
				url: '/meetings/add',
				data: {
					meeting_date: meetingDate,
					meeting_time: meetingTime,
					meeting_location: meetingLocation
				},
				error: function (jqXHR, textStatus, errorThrown) {
					var jsonData = null;

					makeEditable();
					$("#page-spinner").addClass("invisible");

					if (jqXHR && jqXHR.status == 400 && jqXHR.responseText) {
						try {
							jsonData = $.parseJSON(jqXHR.responseText)
						} catch (e) {}

						if (jsonData && jsonData.message) {
							if(jsonData.field) {
								switch(jsonData.field) {
								case "meeting_date":
									errorForControl($("#add-meeting-date-group"), jsonData.message, true);
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
				success: function (data) {
					window.location.href = data.redirect_url;
				}
			});
		}
	});
});
