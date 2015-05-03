window.bbBookClub = window.bbBookClub || {};

window.bbBookClub.Utils = {
	showXhrError: function (xhr, defaultTitle, defaultMessage) {
		return new Promise(function (resolve, reject) {
			xhr = xhr || {};
			xhr.getResponseHeader = xhr.getResponseHeader || function () { return undefined;}

			var messageTitle = xhr.getResponseHeader("X-Bookclub-Error-Title") || defaultTitle || "Something went wrong",
				messageBody = xhr.getResponseHeader("X-Bookclub-Error-Reason") || defaultMessage || "An unknown error has occurred",
				useJson = xhr.getResponseHeader("X-Bookclub-Error-SeeJSON") === "YES", 
				jsonBody;

			if (useJson) {
				try {
					jsonBody = $.parseJSON(xhr.responseText)
				}
				catch (e) {
					jsonBody = null;
				}

				if (jsonBody && jsonBody.detailedMessage) {
					messageBody = jsonBody.detailedMessage;
				}
			}

			bootbox.dialog({
				title: messageTitle,
				message: messageBody,
				buttons: {
					ok: {
						label: "Ok",
						className: "btn btn-primary",
						callback: function () {
							resolve();
						}
					}
				}
			});
		});
	}
};