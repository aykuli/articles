# rvm

Для пользователей Ubuntu есть отдальный репозиторий с таикми особенностями:

* stable rvm is used;
* rvm is installed using mixed-mode install: usable by all users on the system, with isolated rubies/gemsets in user's $HOME (see more here);
* rvm is installed into /usr/share/rvm (as Debian/Ubuntu convention);
* automatic updates provided by a Ubuntu PPA;

Мной люьимые команды:
### Список установленных руби:

```shell
$ rvm list
# No rvm rubies installed yet. Try 'rvm help install'.
```

### Информация некоторая

todo: find out what does means some variables like GEM_HOME

```shell
$ rvm info

system:

  system:
    uname:        "Linux pc 6.2.0-34-generic #34~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Sep  7 13:12:03 UTC 2 x86_64 x86_64 x86_64 GNU/Linux"
    name:         "Ubuntu"
    version:      "22.04"
    architecture: "x86_64"
    bash:         "/usr/bin/bash => GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)"
    zsh:          " => not installed"
    remote_path:  "ubuntu/22.04/x86_64"

  rvm:
    version:      "1.29.12 (manual)"
    updated:      "33 minutes 11 seconds ago"
    path:         "/usr/share/rvm"
    autolibs:     "[4] Allow RVM to use package manager if found, install missing dependencies, install package manager (only OS X)."

  homes:
    gem:          "not set"
    ruby:         "not set"

  binaries:
    ruby:         "/home/a/.rbenv/shims/ruby"
    irb:          "/home/a/.rbenv/shims/irb"
    gem:          "/home/a/.rbenv/shims/gem"
    rake:         "/home/a/.rbenv/shims/rake"

  environment:
    PATH:         "/home/a/.gvm/bin:/home/a/.rbenv/shims:/home/a/.nvm/versions/node/v20.4.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/share/rvm/bin"
    GEM_HOME:     ""
    GEM_PATH:     ""
    MY_RUBY_HOME: ""
    IRBRC:        ""
    RUBYOPT:      ""
    gemset:       ""
```


```shell
$ rvm help install

Ruby enVironment Manager 1.29.12 (manual) (c) 2009-2020 Michal Papis, Piotr Kuczynski, Wayne E. Seguin

## Usage

    rvm install {ruby-string} [--verify-downloads {0,1,2}] [--binary|--disable-binary|--movable]


For a partial list of valid ruby strings please run

    rvm list known

For MRI Rubies you may pass configuration parameters in one of two ways:

    rvm install 1.9.2 --with-iconv-dir=$HOME/.rvm --without-readline

and/or

    rvm install 1.9.2 -C --with-iconv-dir=$HOME/.rvm,--without-readline

To do dirty installation using the same sources use:

    rvm install --force 1.9.2

To do clean installation use:

    rvm reinstall 1.9.2

## Fetching ruby package

You can customize fetching ruby package (source or binary) process with following options:

- `--quiet-curl`         - make `curl` silent when fetching data
- `--force`              - remove old installation with sources and force install

## Architecture

By default RVM will install 64-bit rubies, but you specify alternative
using switches:

- `--32`                   - install 32-bit rubies
- `--64`                   - install 64-bit rubies (default)
- `--universal`            - install both (OSX only)
- `--arch` | `--archflags` - architectures to install

## Binary rubies

By default RVM will try to download binary ruby package instead of compiling.
If such package is not available normal compilation will be performed.
Using binary builds can significantly decrease ruby installation time.

There are two options controlling binary rubies installation:

- `--binary`         - force binary installation, do not try to compile ruby.
- `--disable-binary` - do not try binary ruby, always compile.

More details about managing binary rubies can be found in `rvm help mount`.

## Installing from source

If you installing ruby package by compiling it from source, you can pass
additional configuration options:

- `--reconfigure`      - force `./configure` on install even if `Makefile` already exists
- `--patch`            - with MRI Rubies you may specify additional patches to apply before install - multiple patches should be comma separated `--patch a.patch[%prefix],b.patch` - `prefix` is an optional argument, which will be bypassed to the `-p` argument of the `patch` command and should be separated from patch file name with the `%` symbol.

### Compilation options
- `--clang`                          - use clang for compilation (equivalent to `export CC=clang` + `export CXX=clang++`)
- `--disable-llvm` | `--disable-jit` - disable LLVM
- `--enable-llvm` | `--enable-jit`   - enable LLVM

- `--with-arch`                      - architecture flag for configure (e.g. i686, x86_64)
- `-C` | `--configure` | `--`        - custom configure options - multiple options can be specified, separated with comma
- `--with-*` | `--without-*`         - configure flags
- `--enable-*` | `--disable-*`       - configure flags
- `-E` | `--env`                     - environment flags for configure
- `-M`                               - custom make options

#### .rvmrc equivalents

- `--with-arch`                       `rvm_architectures`
- `-C`                                `rvm_configure_flags`
        ... or per-ruby:              `{jruby|ree|rbx|mruby|macruby|truffleruby}_configure_flags`
- `-E`                                `rvm_configure_env`
- `-M`                                `rvm_make_flags`
- [none]                              `rvm_curl_flags`; default: --max-redirs 10 --max-time 1800

Note: these are not the only options passed to `configure` & `make`. rvm will add multiple options to each. See `RVMPATH/scripts/functions/{build_config,ruby,rubinius,requrements,pkg,...}` for details.

A variable with multiple flags should be set using parentheses and space separators. E.g. .rvmrc for `brew`-based `readline`, `llvm`, and `openssl` libraries:
```
 # warning: don't use \ linebreaks or it will break.
rvm_configure_env=( LDFLAGS="-L$(brew --prefix readline)/lib -L$(brew --prefix llvm)/lib -L$(brew --prefix openssl)/lib" CPPFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix llvm)/include -I$(brew --prefix openssl)/include" CXX=$(brew --prefix llvm)/bin/clang++ CC=$(brew --prefix llvm)/bin/clang )
rvm_archflags="-arch x86_64"
```

### Package-specific options

rbx & jruby:
- `--1.8` | `--1.9` | `--2.0` | `--2.1` - use branch compatible with given MRI ruby version
- `--18` | `--19` | `--20` | `--21`     - same

ree:
- `--ree-options`   - options passed directly to ree's `./installer` on the command line

### Compilation threads

RVM by default will try to detect amount of CPU cores and use `-j <max>`,
specify your own `-j n` flag to RVM to override the default:

    rvm install 2.0.0 -j 50 # OR:
    rvm install 1.8.6 -j 1

### Movable rubies

It is possible to build a ruby that can be moved to other locations, renamed
or even moved to other machine - as long as the system matches.

This option works only for ruby **1.9.3**, ruby **1.9.2** supports this only
on systems without `/usr/lib64`.

More details about managing binary builds can be found in `rvm help mount`.

## Documentation

- `--docs`              - generate ri after installation (default)
- `--rdoc` | `--yard`   - type of docs to generate (default: rdoc)
- `--no-docs`           - disable ri after installation

## Additional settings

- `--skip-gemsets`                     - skip the installation of default gemsets
- `--bin`                              - path for binaries to be placed (default: `~/.rvm/bin/.`)
- `-l` | `--level`                     - MRI ruby patch level
- `--url` | `--repository` | `--repo`  - git URL of repository to install from
- `--branch`                           - branch to install from
- `--tag`                              - tag to install from
- `--sha`                              - SHA of commit to install from
- `--trace`                            - add time, path, etc details to log
- `--proxy`                            - proxy options to pass to curl for downloading packages

## Verification

`--verify-downloads {0,1,2}` specifies verification level:

- `0` - only verified allowed,
- `1` - allow missing checksum,
- `2` - allow failed checksum.

Please see the documentation for further information:

- https://rvm.io/rubies/installing/
- https://rvm.io/rubies/named/

For additional documentation please visit https://rvm.io

```


So, I run:
```shell
rvm install ruby-3.2.2
```
## Sources

1 [https://github.com/rvm/rvm](https://github.com/rvm/rvm)
2 [https://github.com/rvm/ubuntu_rvm](https://github.com/rvm/ubuntu_rvm)