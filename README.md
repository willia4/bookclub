# BB Bookclub
This software is a work-in-progress for managing book clubs, written with a specific book club in mind. 

It's written in Ruby for Sinatra and relies heavily on web services (such as Amazon's SimpleDB and MailChimp's Mandrill) to keep deployment and server management as low-impact as possible.

Using pay-for-use web services is not without a cost; however, at the size of a standard book club, it will hopefully not be burdensome. 

There is a dependency on redis for caching but the server is configurable -- so you may use something like Amazon's ElastiCache if you'd like. A micro instance of that costs about $12/mo. Network bandwidth may be an issue if you're not hosting in EC2 as well, however. 

# Getting Started
BB Bookclub is a [Sinatra][sinatra] app developed and tested under ruby 2.1.3. It uses Amazon's [SDB][sdb] and [S3][s3] for data storage with a local [Redis][redis] 
caching layer for performance. CSS files written in [SCSS][sass] are processed and cached by a dedicated Sinatra endpoint (I ended up with this strange design to avoid having to 
run some sort of watch command during development; this decision should be revisted once the CSS files are mostly stable). The UI depends on bootstrap and some Javascript libraries 
which are still in flux. 

[sinatra]: http://www.sinatrarb.com/
[sdb]: http://aws.amazon.com/simpledb/
[s3]: http://aws.amazon.com/s3/
[redis]: http://redis.io/
[sass]: http://sass-lang.com/

## Vagrant
To make all of this a little easier to manage, I've created a [Vagrant][vagrant] file and a set of ansible provisioning playbooks to set up a development environment including [rvm][rvm], 
[Redis][redis], and [Phusion Passenger][passenger] running under [nginx][nginx]. I should probably swtich to [Unicorn][unicorn] at some point, but the current system is working
and switching it out doesn't sound like fun. 

You may do whatever you'd like, but if you want to mimic my development environment, you are welcome to. 

*Note: Vagrant and VirtualBox both support Windows, but I have no idea how things like `vagrant ssh` will work there. [Good luck][luck].*

[vagrant]: https://www.vagrantup.com/
[rvm]: https://rvm.io/
[passenger]: https://www.phusionpassenger.com/
[nginx]: http://wiki.nginx.org/Main
[unicorn]: http://unicorn.bogomips.org/
[luck]: http://stackoverflow.com/questions/9885108/ssh-to-vagrant-box-in-windows

#### Docker 
There is also a Dockerfile which can be used to build a container image for deployment. This is less useful for development as the source code is burned in to the created image (though that could be worked around with the right -v flag).

The Docker image  does not contain a secrets.yaml file. Instead, the container must be configured via environment variables when running the container. The bottom of this file lists the environment variables that must be set. The most correct version of this list can also be found by reading `src/config.ru`. 

### Step 1 - Install Vagrant
Follow the [getting started instructions][vagrant_start] for Vagrant to install and become familiar with Vagrant. My Vagrantfile uses the [ubuntu/trusty32][trusty] box which works 
fine under [VirtualBox][virtualbox]

[vagrant_start]: http://docs.vagrantup.com/v2/getting-started/index.html
[trusty]: https://vagrantcloud.com/ubuntu/boxes/trusty32
[virtualbox]: https://www.virtualbox.org/

### Step 2 - Set up project directory
For convenience and distribution, the Vagrant files currently live at the top level of this repo.

Confirm that your project directory contains a `Vagrantfile`, a `provision` directory (with several .yml and other files in it)
and a `src` directory containing the application source.

### Step 3 - Examine the Vagrant files

1. Read over the `Vagrantfile` to get a sense of what it will do. The list of provisioning steps are at the bottom of the file. 
2. Read each of those provisioning files in order to get a sense of what will happen.

### Step 4 - Bring up Vagrant
*Note: This step may take a while*

1. Enter your project directory
2. Run the command `vagrant up`. Vagrant should download the appropriate box and run the provisioning steps

### Step 6 - Explore the Vagrant box
From the project directory, you can use the `vagrant ssh` command to bring up an SSH shell into the box. From inside the virtual machine, the source is located at `/www`. 

Before running `irb` or other ruby commands, you will need to ask rvm to change your environment to the correct ruby version. 
When you provision the box, the current set of required gems will be installed. If you add additional dependencies, you 
may install them with the following steps: 

1. From a "real" command prompt, change into your project directory and enter the `vagrant ssh` command to open an SSH shell into the virtual machine
2. Change into the virtual source directory with `cd /www`
3. Switch to the correct ruby environment with `rvm use 2.1.3`
4. In the `/www` directory, install the needed gems by running `bundle install`

Site errors over the course of development will be logged to `/var/log/nginx/errors` . You will need to become the superuser in order to `cat` this log by running `sudo su`. You will not be prompted for a password. 

### Step 7 - Configure the site

You can access the site now at [http://localhost:8080/](http://localhost:8080/) but you will see an error that the `secrets.yaml` file is missing. This is because the site 
still requires configuration. Follow the instructions below in the **Configuration** section.

### Step 8 - Init SDB

Now that you have confingured Amazon's web services, SDB needs to be initailized. You can do this from inside the Vagrant box.

1. From a "real" command prompt, change into your project directory and enter the `vagrant ssh` command to open an SSH shell into the virtual machine
2. Change into the virtual source directory with `cd /www/bookclub`
3. Switch to the correct ruby environment with `rvm use 2.1.3`
4. Start the interactive ruby interpreter with `irb`
5. In irb, load YAML with `require "yaml"` - ruby should return `=> true`
6. In irb, load your configuration with `$config = YAML::load(File.open("secrets.yaml"))` - ruby should return a hash of your secrets file
7. In irb, load the Database module with `load "./Database/Database.rb"` -- ruby should return `=> true`
8. In irb, init AWS with `Database.init_amazon` -- ruby should return an array of SDB domains starting with your domain prefix


### Step 9 - Test the site

Once the site is configured, you should be able to access it at [http://localhost:8080/](http://localhost:8080/). (The port number is configurable in the Vagrantfile.)

# Configuration
This project is missing a `secrets.yaml` [YAML][yaml] file which contains configuration information. There is a `secrets.yaml.sample` in the main source code directory. 
Rename it to `secrets.yaml` and then edit it to provide the appropriate information. You will need to acquire several different API keys from various services. 

[yaml]: http://yaml.org/

## AWS SDB
 
You will need an [Amazon Web Services][aws] account with a Simple DB user. Most data is stored in SDB. 
Permissioning an SDB user is beyond the scope of this document; but once you have configured it, provide the 
configuration information in `secrets.yaml` under the `aws\sdb` section. AWS is not free but it is affordable at low volumes: I rarely spend more than $0.17 - $0.25 per month, total.

* **region** - The AWS region you will be using. `us-east-1` is Amazon's default.
* **access_key** - The AWS IAM user access key that is permissioned for SDB.
* **secret** - The AWS IAM user secret that is permissioned for SDB.
* **domain_prefix** - Multiple applications can store data in a single SDB account. This specifies the prefix that will uniquely identify this application instance in the AWS IAM user account. Domains are securable by prefix. See Amazon's documentation for more. 

## AWS S3

You will need an [Amazon Web Services][aws] account with an S3 user. Large and binary data is stored in S3. 
Permissioning an S3 user is beyond the scope of this document; but once you have configured it, provide the configuration information in `secrets.yaml` under 
the `aws\s3` section. AWS is not free but it is affordable at low volumes: I rarely spend more than $0.17 - $0.25 per month, total. 

* **region** - The AWS region you will be using. `us-east-1` is Amazon's default.
* **access_key** - The AWS IAM user access key that is permissioned for S3.
* **secret** - The AWS IAM user secret that is permissioned for S3.
* **bucket** - Multiple applications can store data in a single S3 account. This specifies the bucket that will uniquely identify this application instance in the AWS IAM user account. Buckets are individually securable. See Amazon's documentation for more. 

[aws]: http://aws.amazon.com/

## CSS

The application can serve both standard CSS files and SCSS files (after parsing). The `css` section allows you to customize where those files are served from. This should not need to be changed.

* **css_path** - Where standard CSS files are stored and served from
* **scss_path** - Where SCSS files are stored, transformed, and served from

## Facebook

The application uses Facebook for user authentication. You will need a Facebook application account from [https://developers.facebook.com/](https://developers.facebook.com/). Once you have acquired this, provide the configuration information in `secrets.yaml` under the `facebook` section. 

* **app_id** - Your Facebook app ID
* **secret** - Your Facebook app secret

## Goodreads

Book information is retrieved from Goodreads. You will need an API key from [https://www.goodreads.com/api](https://www.goodreads.com/api). Once you have acquired this, provide it 
in `secrets.yaml` under the `goodreads` section.

* **api_key** - Your Goodreads API key

## SMTP

The application uses a standard SMTP server to send transactional email. I recommend a [Mandrill](https://mandrill.com/) account, but any standard SMTP server should suffice. Once you have acquired this information, provide it in `secrets.yaml` under the `smtp` section. 

* **server** - The STMP server name or IP address
* **port** - The SMTP server port
* **username** - The SMTP user name
* **password** - The SMTP password
* **from_address** - The from address to use in any generated emails. Recommended: "BB Bookclub <you@youremail.com>"

## Redis

The application uses Redis to provide an in-memory cache of data. If you used the Vagrantfile above to set up your development environment, this sample settings will match
what you need. You may customize this to fit your needs in `secrets.yaml`, however, in the `redis` section.

* **server**: The redis server name or IP address
* **port**: The redis server port
* **db**: The redis DB to use

## General

The application allows some general settings to be configured from `secrets.yaml` in the `general` section.

* **site_name**: The name of the site: displayed in the site banner, in transational emails, etc.
* **base_url**: The base URL of the site. This is used to generate hyperlinks when rendering pages.
* **login_cookie**: The site will store session tokens in this cooke
* **mode**: The site will change certain parameters depending on if it is in DEV or PROD mode. For example, caches will expire much faster in DEV mode than in PROD mode. 

## Future

Future development may require changes to the `secrets.yaml` file. No migration will be provided. Follow the commit log for more details. 

## Environment Variables
The application can also be configured via environment variables. When there is a conflict, the environment variables will supersede the values in the secrets.yaml file. 

### AWS SDB Config
* BOOKCLUB_AWS_SDB_REGION
* BOOKCLUB_AWS_SDB_ACCESSKEY
* BOOKCLUB_AWS_SDB_SECRET
* BOOKCLUB_AWS_SDB_DOMAINPREFIX

### AWS S3 Config
* BOOKCLUB_AWS_S3_REGION
* BOOKCLUB_AWS_S3_ACCESSKEY
* BOOKCLUB_AWS_S3_SECRET
* BOOKCLUB_AWS_S3_BUCKET

### CSS Config
* BOOKCLUB_CSS_CSSPATH
* BOOKCLUB_CSS_SCSSPATH

### Facebook Config
* BOOKCLUB_FACEBOOK_APPID
* BOOKCLUB_FACEBOOK_SECRET

### Goodreads Config
* BOOKCLUB_GOODREADS_APIKEY

### General Config
* BOOKCLUB_GENERAL_SITENAME
* BOOKCLUB_GENERAL_BASEURL
* BOOKCLUB_GENERAL_LOGINCOOKIE
* BOOKCLUB_GENERAL_MODE

### SMTP Config
* BOOKCLUB_SMTP_SERVER
* BOOKCLUB_SMTP_PORT
* BOOKCLUB_SMTP_USERNAME
* BOOKCLUB_SMTP_PASSWORD
* BOOKCLUB_SMTP_FROMADDRESS

### Redis Config (Optional - will default to local instance)
* BOOKCLUB_REDIS_SERVER
* BOOKCLUB_REDIS_PORT
* BOOKCLUB_REDIS_DB