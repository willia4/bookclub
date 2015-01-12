# BB Bookclub

This software is a work-in-progress for managing book clubs, written with a specific book club in mind. 

It's written in Ruby for Sinatra and relies heavily on web services (such as Amazon's SimpleDB and MailChimp's Mandrill) to keep deployment and server management as low-impact as possible.

Using pay-for-use web services is not without a cost; however, at the size of a standard book club, it will hopefully not be burdensome. 

There is a dependency on redis for caching but the server is configurable so you may use something like Amazon's ElastiCache if you'd like. A micro instance of that costs about $12/mo. 

# Configuration
This project is missing a secrets.yaml file which contains configuration information. When the configuration is more stable, I'll add a secrets.sample.yaml file to show the shape of it. 
For now, email the maintainer to get a current sample.

# TODO

* Delete Users
	* This is relatively easy to implement, except we need to figure out what to do with artifacts that are tied to that user. I've decided to save that for another day.
* Google Login in addition to Facebook; possibly others as well
	* In particular, users should be able to link multiple external authenticated accounts to their local accounts so they can pick whichever "Login With FOO" button makes them happy at the moment
* Book Nominations 
	* Goodreads integration
	* Need to determine if books are nominated for each meeting or if there is a pool of books that are ranked for all time
* Book Voting
* Meetings
* Profile editing