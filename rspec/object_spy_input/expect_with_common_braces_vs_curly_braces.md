# RSpec faking I/O

Читала я давече книгу Effective testing with RSpec 3 и застряла в главе тестирования консольного вывода результата.

Интересно, такое где может понадобиться? Встраиваемое программирование интересно, есть в рубях?

В общем, там есть задача, наверно все рубисты читали/решали ее.


## expect() vs expect {}

```ruby
RSpec.describe 'expect' do
  it 'works with usual braces' do
    expect(1).to eq 1.0
  end

  it 'works with curly braces' do
    expect { [1,2].map{ _1 * 2 } }.to eq [2, 4]
  end
end
```

дает ответ:
```ruby
a:test$ rspec test.rb -fd

expect
  works with usual braces
  works with curly braces (FAILED - 1)

Failures:

  1) expect works with curly braces
     Failure/Error: expect { [1,2].map{ _1 * 2 } }.to eq [2, 4]
       You must pass an argument rather than a block to `expect` to use the provided matcher (eq [2, 4]), or the matcher must implement `supports_block_expectations?`.
     # ./test.rb:7:in `block (2 levels) in <top (required)>'

Finished in 0.00136 seconds (files took 0.08038 seconds to load)
2 examples, 1 failure

Failed examples:

rspec ./test.rb:6 # expect works with curly braces

```

В документации про метод [supports_block_expectations?](RSpec::Matchers::MatcherProtocol#supports_block_expectations?) написано, что этот метод требуется для методов модуля `Matchers`, которые работают с побочным эффектом блока, а не с конкретным объектом.


