# BB Bookclub

This software is a work-in-progress for managing book clubs, written with a specific book club in mind. 

It's written in Ruby for Sinatra and relies heavily on web services (such as Amazon's SimpleDB and MailChimp's Mandrill) to keep deployment and server management as low-impact as possible.

Using pay-for-use web services is not without a cost; however, at the size of a standard book club, it will hopefully not be burdensome. 

There is a dependency on redis for caching but the server is configurable -- so you may use something like Amazon's ElastiCache if you'd like. A micro instance of that costs about $12/mo. Network bandwidth may be an issue if you're not hosting in EC2 as well, however. 

# Configuration
This project is missing a secrets.yaml file which contains configuration information. When the configuration is more stable, I'll add a secrets.sample.yaml file to show the shape of it. 
For now, email the maintainer to get a current sample.

# TODO

The TODO list is now tracked via [Github Issues](https://github.com/willia4/bookclub/issues)