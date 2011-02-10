# Cerberus #

# Run #

To install and start AMMID:

    $ rvm use 1.9.2
    $ rvm gemset cerberus
    $ rvm gemset use cerberus
    $ gem install bundler
    $ cd cerberus
    $ bundle
    $ shotgun -s thin config.ru

And to test it using curl:

    $ curl -v -u user:token http://localhost:9393/api/v1/data_sources

# Specs #

RSpec options are stored inside *.rspec*. To run all the specs:

    $ bundle exec rspec spec

