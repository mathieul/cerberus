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

Start the server:

    $ bundle exec rackup -s mongrel 2>/dev/null

    or to avoid logging slowing down the server

    $ bundle exec rackup -s mongrel >/dev/null 2>&1

Using httperf (normal usage, regular flow of requests):

    $ bin/cerberus_mgr.rb basic_auth your_user your_password
    Header to add to your HTTP requests: 
    "Authorization: Basic eW91cl91c2VyOnlvdXJfcGFzc3dvcmQ=\n"

    $ httperf --hog --server 127.0.0.1 --port 9292 \
        --add-header "Authorization: Basic eW91cl91c2VyOnlvdXJfcGFzc3dvcmQ=\n" \
        --uri /api/v1/data_sources --wsess=100,1,0 --rate 5 --timeout=5
    [...]
    Request rate: 5.0 req/s (198.0 ms/req)
    [...]

Using ab (DOS attack):

    $ ab -n 10000 -c 15 -A user:pass http://127.0.0.1:9292/api/v1/data_sources
