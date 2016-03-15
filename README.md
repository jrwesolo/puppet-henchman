Henchman
--------

Henchman is a tool that wraps around community-accepted testing tools. This tool aims to reduce the amount of boilerplate code and makes writing and running tests faster.

What This Supports
------------------

| Tool | Description |
| ---- | ----------- |
| [puppet-lint](https://github.com/rodjek/puppet-lint)* | Check that your Puppet manifests conform to the style guide |
| [puppet-syntax](https://github.com/gds-operations/puppet-syntax)* | Syntax checks for Puppet manifests and templates |
| [metadata-json-lint](https://github.com/voxpupuli/metadata-json-lint)* | Tool to check the validity of Puppet metatdata.json files |
| [rspec-puppet](https://github.com/rodjek/rspec-puppet) | RSpec tests for your Puppet manifests |
| [test-kitchen](https://github.com/test-kitchen/test-kitchen) | Integration test harness for infrastructure code and software |

_\* = optional, depends on if corresponding gem is available_

Under The Hood
--------------

### Where is my fixtures.yml?

There is no need for a `fixtures.yml` file to populate module dependencies for testing. Instead, henchman uses [librarian-puppet](https://github.com/rodjek/librarian-puppet) and the dependencies listed in `metadata.json`. This encourages accurate module metadata and a single source of truth for dependencies.

### Test Kitchen

Test Kitchen originally was formed by the Chef community as an easy way to perform integration tests on many different platforms with multiple test suites. Over the years, it has evolved into a very mature project with support for more languages and scenarios. Neil Turner, of the Puppet community, created [kitchen-puppet](https://github.com/neillturner/kitchen-puppet) which enables support for Puppet testing in test-kitchen.

### Directory Structure

The directory structure expected by henchman is drastically different than a more traditional setup expected by [puppetlabs\_spec\_helper](https://github.com/puppetlabs/puppetlabs_spec_helper).

Example module structure with **puppetlabs\_spec\_helper**:

```bash
.
|-- files
|-- lib
|-- manifests
|-- spec
|   |-- acceptance # acceptance tests for beaker
|   |-- classes    # unit tests for rspec-puppet
|   |-- defines    # unit tests for rspec-puppet
|   |-- fixtures   # fixtures for tests
|   |-- functions  # unit tests for rspec-puppet
|   |-- hosts      # unit tests for rspec-puppet
|   |-- types      # unit tests for rspec-puppet
|-- templates
```

Example module structure with **henchman**:

```bash
.
|-- files
|-- lib
|-- manifests
|-- templates
|-- test
    |-- fixtures    # fixtures for tests
    |-- integration # integration tests for test-kitchen
    |-- unit        # unit tests for rspec-puppet
        |-- classes
        |-- defines
        |-- functions
        |-- hosts
        |-- types
```

Usage
-----

### Gemfile

In order to use henchman, it must be declared in the `Gemfile` of the module:

```ruby
# ./Gemfile
source 'https://rubygems.org'

gem 'puppet'
gem 'puppet-henchman'    
gem 'kitchen-vagrant'    # if using vagrant as a kitchen driver
gem 'puppet-lint'        # optional
gem 'puppet-syntax'      # optional
gem 'metadata-json-lint' # optional
```

### Rakefile

Most of the functionality of henchman will be used through rake tasks. To enable these henchman rake tasks, put the following in the `Rakefile` of the module:

```ruby
# ./Rakefile
require 'henchman/rake'
```

### Unit Test Spec Helper

Generally, a `spec_helper.rb` file is created in the `test/unit` folder. Henchman provides some boilerplate code that can be consumed by using the following code:

```ruby
# ./test/unit/spec_helper.rb
require 'henchman/spec_helper'
```

### Rake Tasks

The following rake tasks are the generally used:

| Rake Task | Description |
| --------- | ----------- |
| `style` | Run metadata, lint, and syntax checks if available |
| `unit` | Run rspec unit tests |
| `integration` | Run test-kitchen integration tests |
| `integration:manual` | Prepare for integration tests to be run manually |
| `clean` | Clean up after spec tests |

#### General Workflow

At anytime, run style and unit tests to see how the module code is looking:

```bash
bundle exec rake style
bundle exec rake unit
```

The `integration` stage will **destroy existing instances prior to testing** and **destroy instances after testing**. The integration stage also supports an environment variable `DESTROY` that can control test-kitchen's destroy strategy after tests:

```bash
DESTROY=always  bundle exec rake integration # always destroy instances after tests (default)
DESTROY=passing bundle exec rake integration # only destroy passing instances after tests
DESTROY=never   bundle exec rake integration # never destroy instances after tests
```

As you develop code in an iterative manner, it can be useful to not destroy nodes at the beginning or end of testing and allow them to persist for repeated puppet runs. In this case, test-kitchen can be used directly using the following commands:

```bash
# not in any particular order
bundle exec kitchen converge # run Puppet manifest on instance
bundle exec kitchen verify   # run spec tests on instance
bundle exec kitchen login    # login to instance (generally via ssh)
bundle exec kitchen destroy  # destroy instance
```

Repeated converges and verifies can be run to iteratively test code changes. If Puppet complains about missing modules or dependencies, you will need to run first:

```bash
bundle exec rake integration:manual
```

Click through for additional help on [test-kitchen](https://github.com/test-kitchen/test-kitchen) and [kitchen-puppet](https://github.com/neillturner/kitchen-puppet).