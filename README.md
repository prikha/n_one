# NOne ![CI](https://github.com/prikha/n_one/actions/workflows/ci.yml/badge.svg)

NOne is able to auto-detect N+1 queries with confidence

**Note!** It is a rewrite of similar library https://github.com/charkost/prosopite. All credits go there.

## How it works

NOne monitors all SQL queries using the Active Support instrumentation
and looks for the following pattern which is present in all N+1 query cases:

More than one queries have the same call stack and the same query fingerprint.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_query'
gem 'n_one'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install n_one

## Development Environment Usage

NOne auto-detection can be enabled on all controllers:

```ruby
class ApplicationController < ActionController::Base
  unless Rails.env.production?
    around_action do
      NOne.scan! do
        yield
      end
    end
  end
end
```

## Test Environment Usage
And each test can be scanned with:

```ruby
# spec/spec_helper.rb
config.around(:each) do |example|
  NOne.scan! do
    example.run
  end
end
```

or with custom code using scan report

```ruby
# spec/your_spec.rb
it 'has no N+1 queries' do
  n_ones = NOne.scan do
    MyAction.perform(arguments)
  end
  
  expect(n_ones.size).to eq(0)
end
```

## Whitelisting

Ignore notifications for call stacks containing one or more substrings:

```ruby
  NOne.scan!(whitelist: 'myapp/lib/known_n_plus_ones/') do
    example.run
  end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/prikha/n_one.

## License

NOne is licensed under the Apache License, Version 2.0. See LICENSE.txt for the full license text.
