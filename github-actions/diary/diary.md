# Github Actions. Простой пример для уверенного знакомства

## Содержание

[Введение](#entry)
[1. Workflow файлы](#workflow-files)
[2. Actions](#actions)
[3. Мой пример](#example)
[4. Secrets](#secrets)
[Заключение](#conclusion)

## <span id='entry'>Введение</span>

Здесь я буду расссказывать о моем опыте настройки [CI/CD](https://ru.wikipedia.org/wiki/CI/CD) c помощью [GitHub Actions](https://docs.github.com/ru/actions).
Эта статья поможет тем, кто хочет настроить автоматический деплой для личного/учебного проекта на свой удаленный сервер, пользуясь бесплатным сервисов GitHub Actions. Причем этим сервисом можно пользоваться бесплатно даже с приватным репозиторием (на момент написания статьи).
Акцентирую на тех моментах, которые для меня оказались не самыми очевидными, читая [краткое руководство](https://docs.github.com/ru/actions/quickstart#creating-your-first-workflow) от Github.
Предполагается, что вы уже знаете как пользоваться Github. По большому счету не важно, какой у вас язык программирования или стек: главное - понять, как работают Github Actions и уметь применить его для любого проекта.

## <span id='workflow-files'>1. Workflow файлы</span>

Начнем с создания `workflow` файла, с помощью которого Github запускает Actions. На вкладке `Actions` на странице репозитория на базе вашего кода Github предлагает разные шаблоны `workflow` файла, начнем с `Simple workflow`.

![Simple workflow](img/2.png)

После нажатия на кнопку `Configure` вы увидите содержимое файла.
<details>
   <summary>Пример базового workflow файла simple.yml</summary>
   
   ```sh
name: CI
on:
   # События, которые запускают jobs
    push:
      branches: [ "main" ]
    pull_request:
      branches: [ "main" ]

# jobs запускаются параллельно, если не указана последовательность
jobs:
    # Название job вы можете назвать как угодно
    my_build_job:
      # Операционная система, в которой запускаются процессы
      runs-on: ubuntu-latest
        # Шаги
        steps:
          # Actions от github: проверяет репозиторий, гит и т.д.
          - uses: actions/checkout@v3

          # Пример однолинейного простого скрипта shell
          - name: Run a one-line script
            run: echo Hello, world!

          # Пример многолинейного скрипта shell
          - name: Run a multi-line script
            run: |
                echo Add other actions to build,
                echo test, and deploy your project.

```
</details>

Читаю файл: workflow файл запускает [jobs](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#jobs) с названием `my_build_job` при событиях отправки кода в репозиторий и создания Pull Request на ветке `main`. `my_build_job` запускается на ОС Ubuntu, использует `action` с названием `actions/checkout@v3` и выполняет 2 шага: пишут в консоль однострочный и многостроный тексты.

После создания `name-of-your-wokflow-file.yml` файла, в репозиторий у вас появится папка c файлом `.github/workflows/name-of-your-wokflow-file.yml`. Workflow файлов можно создавать несколько.

Итак, смысл состоит в том, чтоб запустить процессы при определенном действий на выбранной вами ветке.

Например, "сделать деплой" - значит нам нужно запустить процессы:
- проверка кода линтером
- запуск тестов
- получение изменений в файлах в папке проекта на удаленном сервере.
- перезапуск каких-то сервисов проекта (контейнеров, перезапись папок/файлов) на удаленном сервере, чтоб изменения вступили в силу.

А если написать с учетом workflow файла, более подробно эта последовательность будет такова:
* Github создает операционную систему(без пользовательского интерфейса)
* Проверяет ваш репозиторий: его наличие, git, нужные ветки, авторизацию.
* Копирует в эту операционную систему ваш репозиторий после успешной проверки
* Запускает проверку кода, тесты.
* Отправляет изменения, которые вы внесли в ваш репозиторий, на ваш удаленный сервер.
* Делает действия для вступления в силу ваших изменений на вашем сайте.

Обычно проверку кода, запуск тестов и деплой разделяют на отдельные `job`, которые запускают отдельные [`runners`](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#runners). Раннер - это сервер, который запускает одну `job`.

## <span id='actions'>2. Actions</span>

Самое интересное в workflow-файле - `actions` в строке `uses`. В простейшем примере выше это - [actions/checkout@v3](https://github.com/actions/checkout). Можно посмотреть в исходном коде, что делает `action`. Но проще посмотреть на странице выполнения `job`, после того, как вы его запустите:
   * копирует переменные внутрь контейнера
   * проверяет версию git, создает папки нужные, пишет файл настройки
   * проверяет репозиторий
   * авторизируется
   * копирует репозиторий внутрь контейнера
   * переходит на ветку main
![actions/checkout@v3](img/7.png)

Существует множество `actions`, созданные разработчиками, которые можно использовать, выбрав нужный на [Github Marketplace](https://github.com/marketplace/).
Например, в своих нуждах я использовала [D3rHase/ssh-command-action@v0.2.2](https://github.com/marketplace/actions/ssh-command), который запускает мою консольную команду через [ssh](https://en.wikipedia.org/wiki/OpenSSH) на удаленном сервере.

## <span id='example'>3. Мой пример</span>

Мой проект-пример создан генератором Ruby on Rails, потому что примеры без начинки не являются примерами. Я выбрала шаблонный workflow-файл из предложенных Github и дописала его под свои нужды.
Мой примерный список требуемых действии для CI/CD. В файле rubyonrails.yml последовательность процессов такая:

1. Проверила линтером код
2. Запустила тесты
3. Действия на удаленном сервере:
   1. Переход в папку с проектом.
   2. Получение изменений из репозитория используя `git pull`.
   4. Пересоздание docker контейнеров с проектом.

У вас действия могут быть другие. Например, если проект - это браузерное клиентское приложение, то нужно сгенерировать конечные файлы с командой `npm run build` и скопировать файлы в определенную папку на удаленном серере, из которой кушает уже настроенный nginx. В этом случае для копирования подошел бы [garygrossgarten/github-action-scp@v1.0](https://github.com/marketplace/actions/run-commands-via-ssh)

<details>
<summary>Мой пример .github/workflows/rubyonrails.yml</summary>

```sh
# This workflow will install a prebuilt Ruby version, install dependencies, and
# run tests and linters. Then it pulls new features from my repo and
# rebuild containers on remote server through ssh.

name: "Ruby on Rails CI"
on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Ruby and gems
        uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
        with:
          bundler-cache: true
      - name: Lint Ruby files
        run: bundle exec rubocop

  test:
    needs: lint
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        ports:
          - "5432:5432"
        env:
          POSTGRES_DB: rails_test
          POSTGRES_USER: rails
          POSTGRES_PASSWORD: password
    env:
      POSTGRES_DB: rails_test
      POSTGRES_USER: rails
      POSTGRES_PASSWORD: password
      RAILS_ENV: test
      DATABASE_URL: "postgres://rails:password@localhost:5432/rails_test"
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Ruby and gems
        uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
        with:
          bundler-cache: true
      - name: Set up database schema
        run: bin/rails db:schema:load
      - name: Run tests
        run: |
          bundle exec rake db:drop db:create db:migrate db:seed;
          bin/rake test;

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Ruby and gems
        uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
        with:
          bundler-cache: true
      - name: Run command on remote server
        uses: D3rHase/ssh-command-action@v0.2.2
        with:
          host: ${{secrets.SSH_HOST}}
          user: ${{secrets.SSH_USER}}
          private_key: ${{secrets.SSH_PRIVATE_KEY}}
          command: |
            cd ${{ secrets.PROJECT_FOLDER }};
            git checkout main;
            git pull;
            docker-compose --file docker-compose.prod.yml down;
            docker-compose --file docker-compose.prod.yml up -d;
            docker system prune --all --force;
```
</details>


Workflow файл запускается при внесении изменений или создании Pull Request на ветке main. Выполняю 3 `jobs` с названиями `lint`, `test` и `deploy`. Каждый раннер запускается в Ubuntu, проверяет репозиторий с помощью `actions/checkout@v3`, устанавливает Ruby и нужные библиотеки с помощью `ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4`. Линтер проверяет код с помощью библотеки `rubocop`. Для тестов мне нужна база данных, она запускается сервисом `postgres` с тестовыми переменными окружения. На этом шаге также проверяется схема БД, запускаются сиды и, собственно, сами тесты. На шаге деплоя я выполняю консольные команды на удаленном сервере с помощью `action` [D3rHase/ssh-command-action@v0.2.2](https://github.com/marketplace/actions/ssh-command). Далее перехожу в папку с проектом на удаленном сервере, перехожу на ветку main, притягиваю изменения из репозитория, перезапускаю docker сервисы, чищу лишнее, связанное с docker.
Как вы понимаете, на моем удаленном сервере предварительно настроен `git`, `docker`, `docker-compose`, Github подружен с сервером с помощью SSH-ключа.
Раннеры выполняются последовательно, для этого используется ключевое слово `needs` в теле `job`.
Визуально раннеры на Github выглядят симпатично и интуитивно понятно.

![Runners in interface](img/7.png)

Можно зайти в каждый прямоугольник и посмотреть детальнее, что там происходит. Если что-то идет не так, там внутри можно почитать, что не получилось, также можно в скриптах написать для себя визуальные делители или вывод каких-то данных, типа списка файлов.

<details>
<summary>
Пример промежуточного файла на этапе настройки процесса.
</summary>

```sh
- name: Run command on remote server
   uses: D3rHase/ssh-command-action@v0.2.2
   with:
      host: ${{secrets.SSH_HOST}}
      user: ${{secrets.SSH_USER}}
      private_key: ${{secrets.SSH_PRIVATE_KEY}}
      command: |
        echo '--- START WORK ON REMOTE SERVER ---';
        cd ${{ secrets.PROJECT_FOLDER }};
        echo '--- LIST OF FILES ---';
        ls -al;
        echo '--- GIT INFORMATION ---'
        git co dev;
        git pull;
        echo '--- DOCKER OPERATIONS ---';
        docker-compose down;
        echo '--- LIST OF DOCKER CONTAINERS AFTER STOPING DOCKER CONTAINERS ---';
        docker ps;
        docker-compose --file docker-compose.prod.yml up -d;
        docker system prune --all --force;
        echo '--- LIST OF DOCKER CONTAINERS AFTER STARTING DOCKER CONTAINERS ---';
        docker ps;

```
</details>


После настройки процесса CI/CD можно удалить лишнее.

## <span id='secrets'>4. Secrets</span>
В rubyinrails.yml файле есть переменные, которые вызываются из объекта `secrets`. Эти переменные нужны для того, чтобы подружить ваш удаленный сервер с создающимися контейнерами на Github на время выполнения действии. Для этого я сделала шаги:

1. Сгенерировала SSH ключ на удаленном сервере:

```

cd ~/.ssh; ssh-keygen -t ed25519 -C "your_email@example.com"

```

Скажем, я назвала созданные файлы test и получила 2 файла - приватный и публичные ключи.
![Public and private keys](img/4.png)

2. Содержимое приватного ключа я скопировала в переменную в `SSH_PRIVATE_KEY` во вкладке `Settings ->Secrets -> Actions`
3. Создала еще переменные `SSH_HOST` и `SSH_USER`, `PROJECT_FOLDER` с соответствующим содержимым.
   
![Secrets](img/5.png)


## <span id='conclusion'>Заключение</span>
Итого по статье показано:
- Как создавать workflow.yml файлы, которые будут запускать нужные вам действия.
- Где и как искать нужные вам `actions` или самому написать однострочный или многстрочный bash-скрипт, если задача простая.
- Где хранить секретные переменные, которые вы можете использовать в вашем workflow файле.
- Как дебажить в случае ошибок.

Удовольствия вам от программирования!
