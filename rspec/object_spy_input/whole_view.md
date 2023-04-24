# Парк библиотек RSpec

При установке rspec я обнаружила, что установила не одну, а несколько библиотек. Я задумалась - почему?
Понятно, конечно, что разработчики умные все продумали, испытали опытом, но все же?

Список я взяла из Gemfile.lock:
rspec (3.12.0)
  rspec-core (~> 3.12.0)
  rspec-expectations (~> 3.12.0)
  rspec-mocks (~> 3.12.0)
rspec-core (3.12.0)
  rspec-support (~> 3.12.0)
rspec-expectations (3.12.0)
  diff-lcs (>= 1.2.0, < 2.0)
  rspec-support (~> 3.12.0)
rspec-mocks (3.12.0)
  diff-lcs (>= 1.2.0, < 2.0)
  rspec-support (~> 3.12.0)
rspec-rails (5.1.2)
  actionpack (>= 5.2)
  activesupport (>= 5.2)
  railties (>= 5.2)
  rspec-core (~> 3.10)
  rspec-expectations (~> 3.10)
  rspec-mocks (~> 3.10)
  rspec-support (~> 3.10)
rspec-support (3.12.0)

В [главном репозиторий rspec](https://github.com/rspec/rspec-metagem) написано, что это rspec-metagem, который зависит от  rspec-core, rspec-expectations and rspec-mocks. Команда ниже установит все три независимые по сути библиотеки:

```shell
gem install rspec
```

## Выжимка о свойствах каждой библиотеки

### rspec-core:

* делает команду rspec доступной из консоли
* делает доступным команды, которые создают структуру тестов (describe, context, it, specify, example, shared_examples, include_examples, shared_context, include_context, let, before,after,around хуки, described_class)

### rspec-expectations


* обеспечивает команду expect со всем его хозяйством (mathcers):

Базовый пример:

```ruby
expect(something) # ожидает значение
expect { do_something } # ожидает выполняемый блок

expect(actual).to eq(3) # прямое ожидание

expect(actual).not_to eq(3) # обратное ожидание
```



## Namespace

RSpec
  |- Expectations
      |- Configuration
      |- ExpectationNotMetError
      |- ExpectationTarget
          |- InstanceMethods
      |- MultipleExpectationsNotMetError
      |- Syntax
  |- Matchers
      |- AliasedMatcher
      |- BuiltIn
          |- Be
          ...
          |- YieldControl
      |- Composable
      |- DSL
      |- EnglishPhrasing
      |- ExpectedsForMultipleDiffs
      |- FailMatchers
      |- MatcherProtocol



## Источники

1. [https://www.rubydoc.info/](https://www.rubydoc.info/)
2. 