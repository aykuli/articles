# ActionText в Ruby on Rails. Пользуемся и понимаем как.

Содержание

[Цель](#goal)
[Сгенерированные файлы](#generated)
[Связи в таблицах](#tables-relations)
[Как экземпляр нашей модели связывается с экземпляром ActionText в таблице action_text_rich_texts?](#how-model-links-to-active-text)
[Как сохраняются файлы/рисунки в записях?](#how-active_storage_blobs-save-files)
[Настройка сохранения файлов на Minio сервер](#minio)


## <span id='goal'>Цель</span>

Возможность создания, хранения и редактирования текста с рисунками, прикрепленными файлами - частая задача. Разработчику дают такую задачу, а наша (разработчиков) задача - сделать удобный инструмент контент-менеджеру.
В [Ruby on Rails](https://rubyonrails.org/) для этой цели есть модуль [ActionText](https://api.rubyonrails.org/classes/ActionText.html) с [соответствующей  документацией](https://guides.rubyonrails.org/action_text_overview.html), который добавляет возможность редактирования текста в Rails. Он включает в себя редактор [Trix](https://trix-editor.org/), который написан на JavaScript, запускается на стороне клиента(браузера) и рисует довольно дружественный редактор.

![Trix редактор](img/trix_looks_like.png)

## <span id='generated'>Сгенерированные файлы</span>
Для начала устанавливаем нужные библиотеки командой:
```
bin/rails action_text:install
```

После выполнения этой команды вы увидите множество измененных и сгенерированных файлов:

![Список измененных и сгенерированных файлов командой `bin/rails action_text:instal`](img/generated_and_changed_files.png)

Для понимания хорошо бы прочитать эти файлы, чтобы понимать, что происходит. Пройдемся по ним и узнаем:
#### 1. `Gemfile`, `Gemfile.lock`

Предыдущим действием мы устанавили гем [image_processing](https://github.com/janko/image_processing). Этот пакет нужен, чтобы обрабатывать(сжимать, изменять размер) и загружать рисунки в добавляемый контент. Этот гем использует либо [ImageMagick](https://www.imagemagick.org/)/[GraphicsMagick](https://www.imagemagick.org/), либо [libvips](http://libvips.github.io/libvips/).

В `Gemfile.lock` можно посмотреть установленные библиотеки-зависимости для `image_processing`. Нужность их описана [здесь](https://guides.rubyonrails.org/active_storage_overview.html#requirements). 
Для работы этого гема я добавила в `config/application.rb` строку:

```ruby
config.active_storage.variant_processor = :mini_magick
```

В последней версии Rails в файле `config/initializers/new_framework_defaults_7_0.rb:77` написано, что `:mini_magick` еще не `deprecated`.
#### 3. `app/javascript/application.js`

Здесь импортировали JavaScript библиотеки [trix](https://www.npmjs.com/package/trix) и [@rails/actiontext](https://www.npmjs.com/package/@rails/actiontext)

#### 4. `config/importmap.rb`
Здесь создаются соотвествия библиотек и сгенерированных js-файлов и отдаются клиенту в соответствии c этими названиями. Тут добавился JavaScript код для `Trix`. В `DevTools` во вкладке `Debugger` можно посмотреть эти соответсвия на рисунке ниже, где
  1 - просматриваемая страница с редактором
  2 - importmap
  3 - собственно прожеванные файлы (js - ниже, css - выше)
  4 - trix редактор в браузере.

![Importmap в действии](img/importmap-description.png)

Напомню, что для генерации компилированных css/js файлов используется команда (см. [The Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html)):
```
bin/rails assets:precompile
```

#### 5. `test/fixtures/action_text/rich_texts.yml` - файл с тестовыми данными.
#### 6. `app/assets/stylesheets/actiontext.css` - стили по умолчанию.

<details>
<summary>Содержимое файла</summary>

```css
.trix-content .attachment-gallery > action-text-attachment,
.trix-content .attachment-gallery > .attachment {
  flex: 1 0 33%;
  padding: 0 0.5em;
  max-width: 33%;
}

.trix-content .attachment-gallery.attachment-gallery--2 > action-text-attachment,
.trix-content .attachment-gallery.attachment-gallery--2 > .attachment, .trix-content .attachment-gallery.attachment-gallery--4 > action-text-attachment,
.trix-content .attachment-gallery.attachment-gallery--4 > .attachment {
  flex-basis: 50%;
  max-width: 50%;
}

.trix-content action-text-attachment .attachment {
  padding: 0 !important;
  max-width: 100% !important;
}
```
</details>

Вроде бы обычный css файл, но мы видим, что при генерации html используется элемент `action-text-attachment`, которого нет в списке [html-элементов](https://developer.mozilla.org/en-US/docs/Web/HTML/Element), но генерируется с [CustomElementRegistry](https://developer.mozilla.org/en-US/docs/Web/API/CustomElementRegistry).

#### 7. `db/migrate/20230210142600_create_active_storage_tables.active_storage.rb`

В этом файле описан класс миграции, создающий таблицы в префиксом `active_storage_`:
* `active_storage_blobs`
* `active_storage_attachments`
* `active_storage_variant_records`

Более подробно эти таблицы описаны в документации [Active Storage Overview](https://edgeguides.rubyonrails.org/active_storage_overview.html).

<details>
<summary>Содержимое файла</summary>

```ruby
# This migration comes from active_storage (originally 20170806125915)
class CreateActiveStorageTables < ActiveRecord::Migration[5.2]
  def change
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :active_storage_blobs, id: primary_key_type do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments, id: primary_key_type do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false, type: foreign_key_type
      t.references :blob,     null: false, type: foreign_key_type

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records, id: primary_key_type do |t|
      t.belongs_to :blob, null: false, index: false, type: foreign_key_type
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [primary_key_type, foreign_key_type]
    end
end
```

</details>

Здесь написаны какие поля создадутся в вышесказанных таблицах, ограничения полей по уникальности первичных и внешних ключей. Например, в таблице `active_storage_attachments` создаются поля:
* `name` с ограничением, что он не должен быть пустым(`null`),
* `record_type`
* `record_id` с типом `bigint`, который с `record_type` создаются с опцией `polymorphic: true` (см. [Active Record Migrations References](https://guides.rubyonrails.org/active_record_migrations.html#references)) 
* `blob_id` с типом `bigint`, ссылающийся на запись `id` из таблицы `active_storage_blobs`, имеющий ограничение внешнего ключа по `blob_id`
* создается ограничение на уникальность комбинации полей `record_type`, `record_id`, `name`,`blob_id`.

#### 8. `db/migrate/20230210142601_create_action_text_tables.action_text.rb`

В этом файле описан класс миграции, создающий таблицы в префиксом `action_text_` (там всего одна таблица):
* `action_text_rich_texts`
В этой таблице в поле `body` и будет хранится контент в виде html. Все ссылки на рисунки и файлы будут сгенерированы при создании этого контента и сразу встроены в текст.

<details>
<summary>Содержимое файла</summary>


```ruby
# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[6.0]
  def change
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :action_text_rich_texts, id: primary_key_type do |t|
      t.string     :name, null: false
      t.text       :body, size: :long
      t.references :record, null: false, polymorphic: true, index: false, type: foreign_key_type

      t.timestamps

      t.index [ :record_type, :record_id, :name ], name: "index_action_text_rich_texts_uniqueness", unique: true
    end
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [primary_key_type, foreign_key_type]
    end
end
```
</details>

После запуска миграции командой `bin/rails db:migrate` в итоге должны появится таблицы в вашей базе данных.


<details>
<summary>Вот так выглядит в `Rubymine Database tool window` созданные таблицы</summary>

![Database tool window](img/rubymine-database-tool.png)
</details>


#### 9. app/views/layouts/action_text/contents/_content.html.erb

<details>
<summary>Содержимое файла</summary>

```
<div class="trix-content">
  <%= yield %>
</div>
```

</details>

Здесь вставляется `body`, который сохранен в виде html, из таблицы `action_text_rich_texts`.

#### 10. `app/views/active_storage/blobs/_blob.html.erb`

<details>
<summary>Содержимое файла</summary>

```html
<figure class="attachment attachment--<%= blob.representable? ? "preview" : "file" %> attachment--<%= blob.filename.extension %>">
  <% if blob.representable? %>
    <%= image_tag blob.representation(resize_to_limit: local_assigns[:in_gallery] ? [ 800, 600 ] : [ 1024, 768 ]) %>
  <% end %>

  <figcaption class="attachment__caption">
    <% if caption = blob.try(:caption) %>
      <%= caption %>
    <% else %>
      <span class="attachment__name"><%= blob.filename %></span>
      <span class="attachment__size"><%= number_to_human_size blob.byte_size %></span>
    <% end %>
  </figcaption>
</figure>

<!--Если хочется иметь возможность скачать файл, можно привести ссылку на файл.-->
<% if !blob.image? %>
  <div>
    <span class="attachment__download"><%= link_to blob.filename, rails_blob_path(blob) %></span>
    <span class="attachment__size">(<%= number_to_human_size blob.byte_size %>)</span>
  </div>
<% end %>
```

</details>

В DevTools сохраненный контент с рисунком выглядит таким образом:
![](img/active_storage_blobs_attachments_html.png)

В этом html куске страницы рисуется предпросмотр файла или изображение, данные о которой сохранены в таблице `active_storage_blobs`.

![](img/active_storage_blobs_saving_files.png)

Описание к рисунку хранится как часть текста в таблице `action_text_rich_texts`.

Недостаток сгенерированного html-файла был в том, что в нем не рисуется ссылка на файл, чтобы его скачать, а иногда хочется. Для этого можно вставить ссылку на файл, застилизовав его. Я добавила условие, чтобы ссылки не было для рисунков.

## <span id='how-model-links-to-active-text'>Как экземпляр нашей модели связывается с экземпляром ActionText в таблице action_text_rich_texts?</span>

В модели мы пишем ассоциацию [has_rich_text](https://api.rubyonrails.org/classes/ActionText/Attribute.html#method-i-has_rich_text).
```ruby
class Note < ApplicationRecord
  has_rich_text :body
end
```
Затем, при создании экземпляра в контроллере

```ruby
class NotesController < ApplicationController
  def create
    @note = Note.create!(note_params)

    redirect_to note_path @note
  end
  
  private

  def note_params = params.require(:note).permit(:title, :body)
end
```

Через `has_rich_text` в модели работает соответствующий [метод](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/actiontext/lib/action_text/attribute.rb#L37) из модуля `ActionText::Attribute`.

[Код этого метода](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/actiontext/lib/action_text/attribute.rb#L37) с репозитория `rails` читаю так:
* Создаются методы для экземпляра модели: предикат `body?`, сеттер и геттер для этого поля.
* Создается [ассоциация](https://guides.rubyonrails.org/association_basics.html#the-has-one-association) `rich_text_body` с именем класса `ActionText::RichText`, с именем поля `name`. `as: :record` - признак [полиморфной связи](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations), что также видно было в миграции при созданий таблицы `action_text_rich_texts`. Эта ассоциация инверсная, то есть из экземпляра модели [ActionText::RichText](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/actiontext/app/models/action_text/rich_text.rb#L8) можно получить значение этого поля через вызов метода `record`.
  
<details>
  <summary>Проверяю в консоли вышенаписанное:</summary>


```ruby
> note = Note.find(1)
=begin
<Note:0x00007efee9a06ce0                                                                
 id: 1,                                                                                  
 title_ru: "What is Lorem Ipsum?",                                                       
 title_en: "РыбаТекст помогает животным",                                                
 hidden: false,                                                                          
 created_at: Sun, 19 Feb 2023 11:24:47.510481000 UTC +00:00,                             
 updated_at: Sun, 19 Feb 2023 11:24:47.613920000 UTC +00:00> 
=end
>
> note.body
=begin
<ActionText::RichText:0x00007efee9848688
 id: 1,                                 
 name: "body",                       
 body: #<ActionText::Content "<div class=\"trix-conte...">,
 record_type: "Note",                   
 record_id: 1,                          
 created_at: Sun, 19 Feb 2023 11:24:47.564128000 UTC +00:00,
 updated_at: Sun, 19 Feb 2023 11:24:47.583755000 UTC +00:00>
=end
>
> action_text_item = ActionText::RichText.find(1)
=begin
<ActionText::RichText:0x00007efee9848688
 id: 1,                                 
 name: "body",                       
 body: #<ActionText::Content "<div class=\"trix-conte...">,
 record_type: "Note",                   
 record_id: 1,                          
 created_at: Sun, 19 Feb 2023 11:24:47.564128000 UTC +00:00,
 updated_at: Sun, 19 Feb 2023 11:24:47.583755000 UTC +00:00>
=end
>
> action_text_item.record
=begin
<Note:0x00007efee9a06ce0                                                                
 id: 1,                                                                                  
 title_ru: "What is Lorem Ipsum?",                                                       
 title_en: "РыбаТекст помогает животным",                                                
 hidden: false,                                                                          
 created_at: Sun, 19 Feb 2023 11:24:47.510481000 UTC +00:00,                             
 updated_at: Sun, 19 Feb 2023 11:24:47.613920000 UTC +00:00>
=end
```
</details>

Итого, видно, что `note.body` и поиск экземпляра `ActionText::RichText` по известному `id` ссылаются на одну и ту же запись, что и показывает, что опция `inverse_of` работает ожидаемо.

## <span id='how-active_storage_blobs-save-files'>Как сохраняются файлы/рисунки в записях?</span>

При создании новой записи в Trix-редакторе, нажимая на значок скрепки вы можете добавить файл. При выборе оного, например, рисунка, в консоли, где запущен сервер, вы можете увидеть, что делается запрос `POST "/rails/active_storage/direct_uploads"`, который обрабатывается [ActiveStorage::DirectUploadsController#create](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/activestorage/app/controllers/active_storage/direct_uploads_controller.rb#L7) с параметрами:
```JSON
{
  "blob": {
    "filename": "cat.jpg",
    "content_type": "image/jpeg",
    "byte_size": 107329,
    "checksum": "JuFhMdR3g4JjS73owAJLQA=="
  },
  "direct_upload": {
    "blob": {
      "filename": "cat.jpg",
      "content_type": "image/jpeg",
      "byte_size": 107329,
      "checksum": "JuFhMdR3g4JjS73owAJLQA=="
      }
    }
  }
```
В `ActiveStorage::DirectUploadsController#create` происходит [сохранение](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/activestorage/app/models/active_storage/blob.rb#L103) нужных параметров этого файла.

<details>
  <summary>Вы можете это видеть выполненной транзакцией в консоли.</summary>

```ruby
TRANSACTION (0.4ms)  BEGIN
ActiveStorage::Blob Create (0.7ms)  INSERT INTO "active_storage_blobs" ("key", "filename", "content_type", "metadata", "service_name", "byte_size", "checksum", "created_at") VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING "id"  [["key", "ikydgdsgyrgupbqqh0wdqtgs75y4"], ["filename", "cat.jpg"], ["content_type", "image/jpeg"], ["metadata", nil], ["service_name", "minio"], ["byte_size", 107329], ["checksum", "JuFhMdR3g4JjS73owAJLQA=="], ["created_at", "2023-02-23 16:35:59.956614"]]
TRANSACTION (0.8ms)  COMMIT
S3 Storage (45.7ms) Generated URL for file at key: ikydgdsgyrgupbqqh0wdqtgs75y4 (http://localhost:9000/main/ikydgdsgyrgupbqqh0wdqtgs75y4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minioadmin%2F20230223%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20230223T163600Z&X-Amz-Expires=300&X-Amz-SignedHeaders=content-length%3Bcontent-md5%3Bcontent-type%3Bhost&X-Amz-Signature=696eaa54d2f921beaa552de1263fdb8b548708d12ebbdd3df6e97d7077dedeff)
```
</details>


Ниже транзакции показана сгенерированная ссылка для сохраняемого файла. Ссылка эта зависит от конфигурации модуля Active Storage в файле `config/storage.yml`, в данном скрине, это - сервис S3 на minio на локальном диске.

Для первого знакомства можно воспользоваться хранением на локальном диске, описанный как `local` в файле `config/storage.yml` и настроенный по умолчанию. В этом случае service будет Disk. Из значение `key` [генерируется название файла и его папка](https://github.com/rails/rails/blob/e9cb3c7b2f63bac810efb46cf8902cadaadcbdcd/activestorage/lib/active_storage/service/disk_service.rb#L99) и все папки с этими файлами хранятся в папке `storage`.
![Сохранение файлов с Active Storage на диске через Disk service ](img/active_storage_blobs.png)

Кроме файлов и рисунков контент-менеджер добавляет текст, нажимает на кнопку Опубликовать и сохраняет запись. Ссылка на файл сохраняется прямо в теле rich_text. При сохранении всего этого добра делается запись в таблицу `active_storage_attachments`, которая сохраняет связь между таблицами `action_text_rich_texts` и `active_storage_blobs`. 
В таблице `active_storage_attachments`:
* в поле `record_id` сохраняется `id` записи из таблицы `action_text_rich_texts`, 
* в поле `record_type` сохраняется название модуля/класса записи из таблицы `action_text_rich_texts`, 
* в поле `blob_id` сохраняется `id` файла/рисунка из таблицы `active_storage_blobs`,
* в поле `name` сохраняется тип файла/рисунка

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
   
Пробуем в нашем редакторе Trix сохранять файлы/рисунки и проверяем, что они сохраняются в Minio. Я проверяла в пользовательском интерфейсе Minio, доступный по ендпоинту Minio на порту 9001.

Итого:
Минимальный цикл CMS(content management system) вроде бы закрыт. Но некоторые вопросы в данной статье остались не раскрытыми. Вопросы, которые я остались для меня открытыми:
* использование пакета [libvips](https://github.com/libvips/libvips) вместо [ImageMagick](https://imagemagick.org/index.php). Пишут, что второй новее и [быстрее](https://github.com/libvips/libvips/wiki/Speed-and-memory-use).
* сохранение нескольких вариантов изображений для разного размера экранов устройств с использованием таблицы `active_storage_variant_records`. В атрибуте `has_many_attached :embeds` класса [ActionText::RichText](https://github.com/rails/rails/blob/b0dd7c7ae21d692b6e38428e8abe0e9538b75711/actiontext/app/models/action_text/rich_text.rb#L15) я не увидела `variant`, как показано в [документации ](https://guides.rubyonrails.org/active_storage_overview.html#has-many-attached).

Удовольствия вам от программирования, друзья!

