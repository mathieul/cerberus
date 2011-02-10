# Cerberus #

# Run #

To install and start AMMID:

    $ rvm use 1.9.2
    $ rvm gemset cerberus
    $ rvm gemset use cerberus
    $ gem install bundler
    $ cd cerberus
    $ bundle
    $ shotgun -s mongrel config.ru

And to test it using curl:

    $ curl -v -u user:token http://localhost:9393/api/v1/data_sources

# Specs #

RSpec options are stored inside *.rspec*. To run all the specs:

    $ bundle exec rspec spec

# Load #

Use httperf.

    $ bin/cerberus_mgr.rb basic_auth your_user your_password
    Header to add to your HTTP requests: 
    "Authorization: Basic eW91cl91c2VyOnlvdXJfcGFzc3dvcmQ=\n"

    $ bundle exec rackup -s mongrel
    $ httperf --hog --server 127.0.0.1 --port 9292 \
        --add-header "Authorization: Basic eW91cl91c2VyOnlvdXJfcGFzc3dvcmQ=\n" \
        --uri /api/v1/data_sources --wsess=100,1,0 --rate 5 --timeout=5
    [...]
    Request rate: 5.0 req/s (198.0 ms/req)
    [...]
