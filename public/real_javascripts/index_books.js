$(document).ready(function () { 
	setTimeout(function () { 
		var moneyWrenchId = "a66f3be26531e82fe0314aaa8d09cf99",
			infoQuakeId = "b4ec8eb4d5b821362c50320064d3fadd",
			monkeyWrench, infoQuake;

		monkeyWrench = $('*[data-id="' + moneyWrenchId + '"]').first();
		infoQuake = $('*[data-id="' + infoQuakeId + '"]').first();

		// console.log(book);
		// book.animate({"height" : '+=100'});

		var real = $("ul.book-list"),
			shadow = $('<ul class="book-list"></ul>'),
			bookEl;

		shadow.append(monkeyWrench.clone());

		real.find("li.book-listing").each(function (i, li) {
			li = $(li)

			if (li.data("id") !== moneyWrenchId && li.data("id") !== infoQuakeId) {
				shadow.append(li.clone());
			}
		});

		shadow.append(infoQuake.clone());

		real.quicksand(shadow.find("li"), {
			adjustWidth: false,
			easing: 'easeInOutQuad'
		});
	}, 2500);
});