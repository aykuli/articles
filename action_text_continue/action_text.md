# ActionText в Ruby on Rails. Пользуемся и понимаем как.

Содержание

[Настройка сохранения файлов на Minio сервер](#minio)

## <span id='minio'>Настройка сохранения файлов на Minio сервер</span>
Так как сохранять файлы в папке с проектом не хочется, я решила отправлять файлы на сервер на Minio. Делаем все согласно [документации](https://guides.rubyonrails.org/active_storage_overview.html#s3-service-amazon-s3-and-s3-compatible-apis) и все получается.

1) **Устанавливаем нужный гем** `aws-sdk-s3`

Прописываем в `Gemfile` строку:
```ruby
gem "aws-sdk-s3", require: false
```
и запускаем в консоли его установку:
```shell
bundle install
```

2) **Пишем конфигурацию** в `config/storage.yml`

```yaml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

minio:
  service: S3
  endpoint: <%= ENV.fetch('MINIO_ENDPOINT') %>
  access_key_id: <%= ENV.fetch('MINIO_ROOT_USER') %>
  secret_access_key: <%= ENV.fetch('MINIO_ROOT_PASSWORD') %>
  region: us-east-1
  bucket: <%= ENV.fetch('MINIO_BUCKET') %>
  force_path_style: true
```

В `.env` файле прописываем используемые переменнные. Напомню, что для использования этих переменных нужен гем `dotenv-rails`.


3) **Настраиваем окружение**
В файле `config/environment/production.rb`(можно и в development.rb) добавляем строку или переписываем уже имеющуюся:

```ruby
config.active_storage.service = :minio
```

4) **В `docker-compose.yml`** добавляем сервис minio:

```yaml
  minio:
     image: minio/minio:latest
     container_name: minio
     volumes:
       - /home/minio:/${MINIO_BUCKET}
     ports:
       - 9000:9000
       - 9001:9001
     environment:
       MINIO_USER: ${MINIO_USER}
       MINIO_PASSWORD: ${MINIO_PASSWORD}
     command: server --console-address ":9001" /${MINIO_BUCKET}
```

5) **Добавляем** в Minio папку сохранения файлов (папку эту называют `bucket`).

Я сделала это через пользовательский интерфейс Minio.

6) **Проверяем**
   
Пробуем в нашем редакторе Trix сохранять файлы/рисунки и проверяем, что они сохраняются в Minio. Я проверяла в пользовательском интерфейсе Minio, доступный на порту 9001.
Это все хорошо работает в режиме разработки.
В режиме production пришлось немножко повозиться.


Итого:
Минимальный цикл CMS (content management system) вроде бы закрыт. Часть работы осталась под капотом, которая покрывается  Но некоторые вопросы в данной статье остались для меня открытыми. Например:
* использование пакета [libvips](https://github.com/libvips/libvips) вместо [ImageMagick](https://imagemagick.org/index.php). Пишут, что второй новее и [быстрее](https://github.com/libvips/libvips/wiki/Speed-and-memory-use).
* сохранение нескольких вариантов изображений для разного размера экранов устройств с использованием таблицы `active_storage_variant_records`. В атрибуте `has_many_attached :embeds` класса [ActionText::RichText](https://github.com/rails/rails/blob/b0dd7c7ae21d692b6e38428e8abe0e9538b75711/actiontext/app/models/action_text/rich_text.rb#L15) я не увидела `variant`, как показано в [документации](https://guides.rubyonrails.org/active_storage_overview.html#has-many-attached).

На сегодня все. Удовольствия вам от программирования, друзья!

