$(document).ready(function () {
	var editButton = $("#edit-book-button"),
		saveButton = $("#edit-book-save-button"),
		cancelButton = $("#edit-book-cancel-button"),
		deleteButton = $("#delete-book-button"),
		bookEl = $("#book-container"),

		bookTitleEl = $("#book-title > div"),
		bookTitleFormEl,
		authorEl = $("#book-author > div"),
		authorFormEl,
		summaryEl = $("#book-summary > div"),
		summaryFormEl,
		externalUrlFormEl = $("#edit-book-external-url"),
		imageUrlFormEl = $("#edit-book-image-url")

		originalValues = {}
		;

	function createFormElements() {
		bookTitleFormEl = $('<input class="form-control" id="edit-book-title" placeholder="Title" type="text"/>');
		bookTitleFormEl.val(originalValues.title);
		bookTitleEl.replaceWith(bookTitleFormEl);

		authorFormEl = $('<input class="form-control" id="edit-book-author" placeholder="Author" type="text"/>');
		authorFormEl.val(originalValues.author);
		authorEl.replaceWith(authorFormEl);

		summaryFormEl = $('<textarea class="form-control" id="edit-book-summary" rows="7"></textarea>');
		summaryFormEl.val(originalValues.summary);
		summaryEl.replaceWith(summaryFormEl);


		$("#book-edit-additional-fields").removeClass("hidden");
		externalUrlFormEl.val(originalValues.externalUrl);
		imageUrlFormEl.val(originalValues.imageUrl);

		deleteButton.prop("disabled", true);
	}

	function removeFormElements() {
		clearErrors();

		bookTitleFormEl.replaceWith(bookTitleEl);
		authorFormEl.replaceWith(authorEl);
		summaryFormEl.replaceWith(summaryEl);

		bookTitleFormEl = null;
		authorFormEl = null;
		summaryFormEl = null;

		$("#book-edit-additional-fields").addClass("hidden");
		$(".book-cover").html('<img src="' + originalValues.imageUrl + '"/>');

		deleteButton.prop("disabled", false);
	}

	function enableFormElements() {
		bookTitleFormEl.attr("readonly", false);
		authorFormEl.attr("readonly", false);
		summaryFormEl.attr("readonly", false);
		externalUrlFormEl.attr("readonly", false);
		imageUrlFormEl.attr("readonly", false);

		saveButton.prop("disabled", false);
		cancelButton.prop("disabled", false);
	}

	function disableFormElements() {
		bookTitleFormEl.attr("readonly", true);
		authorFormEl.attr("readonly", true);
		summaryFormEl.attr("readonly", true);
		externalUrlFormEl.attr("readonly", true);
		imageUrlFormEl.attr("readonly", true);

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
		bookTitleFormEl.parent().removeClass("has-error");
		authorFormEl.parent().removeClass("has-error");
		summaryFormEl.parent().removeClass("has-error");
		externalUrlFormEl.parent().removeClass("has-error");
		imageUrlFormEl.parent().removeClass("has-error");
	}

	imageUrlFormEl.change(function () {
		var inputEl = $(this),
			img_container = $(".book-cover")
			url = inputEl.val(); 

		if (url.match(/^http[s]?/)) {
			img_container.html('<img src="' + url + '"/>');
		} 
		else {
			img_container.html("");
		}
	});

	editButton.click(function () {
		createFormElements();

		editButton.addClass("hidden");
		cancelButton.removeClass("hidden");
		saveButton.removeClass("hidden");
	});

	cancelButton.click(function () {
		removeFormElements();

		editButton.removeClass("hidden");
		cancelButton.addClass("hidden");
		saveButton.addClass("hidden");
	});

	saveButton.click(function () {
		var bookTitle = bookTitleFormEl.val(),
			bookAuthor = authorFormEl.val(),
			bookSummary = summaryFormEl.val(),
			bookExternalUrl = externalUrlFormEl.val(),
			bookImageUrl = imageUrlFormEl.val();

		function validate() {
			var valid = true;
			
			clearErrors();
			valid = errorForControl(bookTitleFormEl, "Title is required", !bookTitle) && valid;
			valid = errorForControl(authorFormEl, "Author is required", !bookAuthor) && valid;
			if (bookExternalUrl) {
				valid = errorForControl(externalUrlFormEl, "External URL must be a valid URL", !bookExternalUrl.match(/^http[s]?/)) && valid
			}
			if (bookImageUrl) {
				valid = errorForControl(imageUrlFormEl, "Image URL must be a valid URL", !bookImageUrl.match(/^http[s]?/)) && valid
			}

			return valid;
		}

		if (validate()) {
			$("#page-spinner").removeClass("invisible");

			$.ajax({
				url: '/books/book/' + originalValues.bookId,
				type: 'POST',
				data: {
					title: bookTitle,
					author: bookAuthor,
					external_url: bookExternalUrl,
					image_url: bookImageUrl,
					summary: bookSummary
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
								case "title":
									errorForControl(bookTitleFormEl, jsonData.message, true);
									break;
								case "author":
									errorForControl(authorFormEl, jsonData.message, true);
									break;
								case "external_url":
									errorForControl(externalUrlFormEl, jsonData.message, true);
									break;
								case "image_url":
									errorForControl(imageUrlFormEl, jsonData.message, true);
									break;
								case "summary":
									errorForControl(summaryFormEl, jsonData.message, true);
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

	originalValues.bookId = bookEl.data("book-id");
	originalValues.title = bookEl.data("book-title");
	originalValues.author = bookEl.data("book-author");
	originalValues.externalUrl = bookEl.data("book-external-url");
	originalValues.imageUrl = bookEl.data("book-image-url");
	originalValues.summary = summaryEl.html() || summaryEl.text();
});