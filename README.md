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
NOne.scan!(whitelist: ['myapp/lib/known_n_plus_ones/']) do
  example.run
end
```

## Ignore names

Ignore queries with names:

```ruby
NOne.scan!(ignore_names: ['SCHEMA']) do
  example.run
end
```

It will skip schema queries(e.g. for column names of a given table)

## Stack trace sanitizing

Sanitize the call stack trace that is used to calculate the query fingerprint:

```ruby
sanitizer = lambda do |stacktrace|
  stacktrace.reject { |s| s.include?('/active_record/relation/delegation.rb') }
end

NOne.scan!(stacktrace_sanitizer: sanitizer) do
  example.run
end
```

Consider the following example:

```ruby
class Foo < ActiveRecord::Base
  def self.bar
    first(5)
  end
end

2.times { Foo.all.bar }
```

The subsequent `Foo.all.bar` call here will not be recognized as an N+1 query since it will have a different call stack trace (see the reason [here](https://github.com/rails/rails/blob/9a400d808bdbebd5ea50cebc79bde591d2669017/activerecord/lib/active_record/relation/delegation.rb#L82-L85)).
This can be fixed with the `stacktrace_sanitizer` option as described above.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/prikha/n_one.

## License

NOne is licensed under the Apache License, Version 2.0. See LICENSE.txt for the full license text.
