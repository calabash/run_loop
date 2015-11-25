## Style

Follow the GitHub Style guide as much as possible.

* https://github.com/styleguide/ruby

1. Avoid commits with trailing or extraneous whitespace.
2. Files should end with a newline.
3. Wrap long lines to ~80 characters.  This makes editing on a laptop or in a
   tmux session easier.  There is no need to be pedantic about this; a
   few characters over is not a problem.
4. Use spaces for indenting; no hard tabs.
5. Use `["a", "b", "c"]` over `%w(a, b, c)`.

A note about `"` vs. `'`.  For a couple of years, the style guide said:

>  Use `""` for interpolated strings and `''` for non-interpolated
>  strings.

I did an analysis of my workflow and I found that I spent a great deal
of time chasing this style.  I've decided it is just not worth the
effort.  Use `"` always.

### Rspec

**Place a newline between expectations that mock and the assertions.**

```
# Incorrect
it '#xcode_version_gte_63?' do
  expect(xcode).to receive(:version?).and_return RunLoop::Version.new("6.3"))
  expect(xcode.version_gte_63?).to be_truthy
end

# Correct
it '#xcode_version_gte_63?' do
  expect(xcode).to receive(:version?).and_return RunLoop::Version.new("6.3"))

  expect(xcode.version_gte_63?).to be_truthy
end
```

**When testing errors, always include a error class.**

```
# Incorrect
it 'invalid argument' do
  expect { some_method('invalid argument') }.to raise_error
end

it 'invalid argument' do
  expect { some_method('invalid argument') }.to raise_error ArgumentError
end
```

