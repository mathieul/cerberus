# Cerberus Demo #

## Setup ##

### Redis Tab ###

Clean-up:

    $ redis-cli
    > flushdb
    > quit

Create user:

    $ rvm use 1.9.2@cerberus
    $ ./bin/cerberus_mgr.rb set_user demo
    token> 1qaz2wsx
    per_minute> 500

    $ ./bin/cerberus_mgr.rb set_user sfdc
    token> 3edc4rfv
    per_minute> 3

Show lock status:

    $ ./bin/cerberus_mgr.rb lock_status 1

Show user info:

    $ ./bin/cerberus_mgr.rb show_user sfdc

### Server Tab ###

Start:

    $ rvm use 1.9.2@cerberus
    $ bundle exec rackup -s mongrel 2>/dev/null

### SFDC Client Tab ###

Salesforce search:

    $ rvm use 1.9.2@cerberus
    $ curl -v -u sfdc:3edc4rfv http://127.0.0.1:9292/api/v1/accounts/search/liveops.json
    > 200 OK
    $ curl -v -u sfdc:3edc4rfv http://127.0.0.1:9292/api/v1/accounts/search/demonstration.json
    > 404 Not Found

Salesforce create:

    $ curl -v -u sfdc:3edc4rfv -d "name=Fidelity&phone=800-771-3382&description=Financial%20Institution" http://127.0.0.1:9292/api/v1/accounts
    > 201 Created

Limited:

    $ curl -v -u sfdc:3edc4rfv http://127.0.0.1:9292/api/v1/accounts/search/liveops.json
    > 403 Forbidden

### Demo Client Tab ###

Show test request:

    $ rvm use 1.9.2@cerberus
    $ curl -v -u demo:1qaz2wsx http://127.0.0.1:9292/api/v1/fakes.json
    > 200 OK

Benchmark (20 reqs/sec with 0s to 2s random processing):

    $ httperf --hog --server 127.0.0.1 --port 9292 \
        --add-header "Authorization: Basic ZGVtbzoxcWF6MndzeA==\n" \
        --uri /api/v1/fakes.json --wsess=200,1,0 --rate 20 --timeout=5
    > [...]
    > Request rate: 17.6 req/s (56.8 ms/req)
    > [...]
    > Reply rate [replies/s]: min 19.6 avg 19.8 max 20.0 stddev 0.3 (2 samples)
    > [...]

DOS attack:

    $ ab -n 10000 -c 15 -A demo:1qaz2wsx http://127.0.0.1:9292/api/v1/fakes.json
    > [...]
    > Non-2xx responses:      9964
    > [...]

