require "autotest/growl"
require "autotest/rspec2"

class Autotest::Rspec2
  alias :orig_setup_rspec_project_mappings :setup_rspec_project_mappings

  def setup_rspec_project_mappings
    orig_setup_rspec_project_mappings
    add_mapping(%r%^app/(.*)\.rb$%) { |_, m|
      ["spec/#{m[1]}_spec.rb"]
    }
  end
end

Autotest.add_discovery { "rspec2" }
