$LOAD_PATH.unshift File.dirname(__FILE__)

require "active_support/core_ext/hash/keys"
require "active_support/core_ext/hash/slice"
require "active_support/core_ext/object/blank"
require "lib/cerberus"
require "lib/cerberus_middleware"
require "lib/configuration"
require "lib/helpers"
require 'api/api'
