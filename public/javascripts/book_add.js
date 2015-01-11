$(document).ready(function () {
	$("#goodreads-search-input").keypress(function (evt) {
		if(event.which === 13) {
			event.preventDefault();
			alert("Enter")
		}
	});
});