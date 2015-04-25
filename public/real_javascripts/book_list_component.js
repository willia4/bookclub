//This is defined as a jQuery plugin for convenience. 

(function ($) {

	$.fn.book_list = function (options) {
		var settings = $.extend({}, $.fn.book_list.defaults, options), 
			parent = this;

		function callbackWithContext(f) {
			var context = {
				widget: parent,
				reloadBooks: reloadBooks
			},
			args = null;

			if (f) {
				if (arguments.length > 1) {
					args = Array.prototype.slice.call(arguments, 1);
				}

				f.apply(context, args);
			}
		}

		function showSpinner() { 
			callbackWithContext(settings.showSpinnerCallback);
		}

		function hideSpinner() {
			callbackWithContext(settings.hideSpinnerCallback);
		}

		function votingBlockHtml(book, size) {
			var html = '';
			
			var makeArrow = function (direction) {
				var arrow = '',
					buttonClass;

				buttonClass = "vote-button vote-button-" + direction;
				if (book[direction + "voted"]) { 
					buttonClass += " vote-selected";
				}

				arrow += '<div class="col-xs-12" style="text-align: center; font-weigth: bold;">'; //TODO
					arrow += '<a href="#" class="' + buttonClass + '" data-id="' + book.book_id + '">';
						arrow += '<span class="glyphicon glyphicon-arrow-' + direction + '"></span>';
					arrow += '</a>';
				arrow += '</div>';
				return arrow;
			};

			html += '<div class="col-sm-' + size + '" style="font-size: 125%">'; //TODO
				html += '<div class="row">'; //up-row
					html += makeArrow("up");
				html += '</div>' //up-row

				html += '<div class="row">'; //vote-row
					html += '<div class="col-xs-12" style="text-align: center">'; //TODO
						html += book.votes;
					html += '</div>';
				html += '</div>'; //vote-row

				html += '<div class="row">'; //down-row
					html += makeArrow("down");
				html += '</div>'; //down-row
			html += '</div>';
			return html;
		}

		function buttonColumnHtml(book, size) {
			var html = '';
			html += 'BUTTONS';
			return html;
		}

		function mainColumnHtml(book, size) {
			var html = '',
				allowsButtons = !!settings.buttons && settings.buttons.length > 0,
				buttonsSize = allowsButtons ? 3 : 0;

			size -= buttonsSize;

			html += '<div class="col-sm-' + size + '">';
			
				//main row
				html += '<div class="row">'; 
					//book image column
					html += '<div class="col-sm-2">'
						if (book.image_url) {
							html += '<a href="' + book.book_url + '"><img class="book-image" src="' + book.image_url + '"/></a>';
						}
					html += '</div>'; //book image column

					//title column
					html += '<div class="col-sm-offset-1 col-sm-9">';
						html += '<div class="row">';
							html += '<div class="col-xs-12 book-title"><a href="' + book.book_url + '">' + book.title + '</a></div>';
						html += '</div>';
						html += '<div class="row">';
							html += '<div class="col-xs-12 book-author">' + book.author + '</div>';
						html += '</div>';
					html += '</div>'; //title column

					if (allowsButtons) {
						html += buttonColumnHtml(book, buttonsSize);
					}

				html += '</div>'; //main row

				//age row
				html += '<div class="row">';
					html += '<div class="col-sm-offset-7 col-sm-5 book-date-added" title="' + book.date_added_formatted + '">';
						html += "Added " + book.age_statement;
					html += '</div>';
				html +='</div>'; //age row

			html += '</div>';

			return html;
		}

		function bookHtml(book) {
			var allowsVoting = settings.votingCallbacks,
				votingColumnSize = allowsVoting ? 1 : 0,
				mainColumnSize = 12 - votingColumnSize,
			 	html = '';

			html += '<li class="row book-listing" data-id="' + book.book_id + '" data-title="' + book.title + '">';
			if (allowsVoting) {
				html += votingBlockHtml(book, votingColumnSize);	
			}
			html += mainColumnHtml(book, mainColumnSize);
			html += '</li>';

			return html;
		}

		function renderBook(book) {
			return $(bookHtml(book));
		}

		function renderBooksInElement(books, element) {
			var data = {};
			if (books.hasOwnProperty(settings.collectionName)) {
				data = books;
			}
			else {
				data[settings.collectionName] = books;
			}

			var book_elements = $.map(data[settings.collectionName], function (value, i) {
				return renderBook(value);
			});

			element.empty();
			element.append(book_elements);

			addEventHandlers();
		}

		function reloadBooks(bookData, callback) {
			if (bookData) {
				replaceBooks(bookData, callback);
			}
			else {
				getBooksFromServerAndCallback(function (serverBookData) {
					replaceBooks(serverBookData, callback);
				})
			}
		}

		function replaceBooks(newBookData, callback) {
			var shadow = $('<ul class="book-list"></ul>'),
				real = $("ul.book-list");

			renderBooksInElement(newBookData, shadow);

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

		function getBooksFromServerAndCallback(callback) {
			if (!settings.getUrl) {
				throw "Caller must specify url to GET books from"
			}	

			showSpinner();

			$.ajax({
				url: settings.getUrl,
				type: "GET",
				dataType: "json",
				success: function (books) {
					if (callback) {
						callback(books);
					}
					
					hideSpinner();
				},
				error: function (xhr, status, errorThrown) {
					hideSpinner();

					throw errorThrown;
				}
			});
		}

		function getBooksFromServerAndRenderInParent() {
			getBooksFromServerAndCallback(function (books) {
					renderBooksInElement(books, parent);		
				});
		}


		function voteUpHandler(event) {
			event.preventDefault();

			var bookId = $(this).data("id");

			removeEventHandlers();
			showSpinner();

			if (!settings.votingCallbacks || !settings.votingCallbacks.voteUp) {
				throw "Voting requires a voteUp callback to be defined";
			}

			callbackWithContext(settings.votingCallbacks.voteUp, bookId, function () {
				hideSpinner();
				addEventHandlers();
			});
		}

		function voteDownHandler(event) {
			event.preventDefault();

			var bookId = $(this).data("id");

			removeEventHandlers();
			showSpinner();

			if (!settings.votingCallbacks || !settings.votingCallbacks.voteDown) {
				throw "Voting requires a voteDown callback to be defined";
			}

			callbackWithContext(settings.votingCallbacks.voteDown, bookId, function () {
				hideSpinner();
				addEventHandlers();
			});
		}

		function rejectHandler(event) {
			event.preventDefault();
			alert("reject");
		}	

		function selectHandler(event) {
			event.preventDefault();
			alert("select");
		}

		function addEventHandlers() {
			if(settings.votingCallbacks) {
				$(".vote-button-up:not(.vote-selected)").on("click", voteUpHandler);
				$(".vote-button-down:not(.vote-selected)").on("click", voteDownHandler);
			}
			if(settings.allowsRejection) {
				$(".book-reject-button").on("click", rejectHandler);
			}
			if(settings.allowsSelection) {
				$(".book-select-button").on("click", selectHandler);
			}
		}

		function removeEventHandlers() { 
			if(settings.votingCallbacks) {
				$(".vote-button-up:not(.vote-selected)").off("click");
				$(".vote-button-down:not(.vote-selected)").off("click");
			}
			if(settings.allowsRejection) {
				$(".book-reject-button").off("click");
			}
			if(settings.allowsSelection) {
				$(".book-select-button").off("click");
			}
		}

		if (settings.initialState) {
			renderBooksInElement(settings.initialState, parent);
		}
		else {
			getBooksFromServerAndRenderInParent();
		}
		
		return parent;
	};

	$.fn.book_list.defaults = {
		getUrl: null,
		initialState: null,
		showSpinnerCallback: null,
		hideSpinnerCallback: null,
		collectionName: "books",
		votingCallbacks: null,
		meetingId: null,
		buttons: null
	};
})(jQuery);