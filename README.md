# nushell-seAPI
A helper module for accessing the Stack Exchange API from Nushell

Recommended: Clone to `seAPI`:

```
git clone "https://github.com/NotTheDr01ds/nushell-seAPI.git" seAPI
```

### Usage

Note: Backoff support is built in.  If a `backoff` is received from the API, the method will pause *before* returning results.  Of course, this assumes that you are not running multiple API processes at the same time, which I'm told can be a problem with *any* usage of the API.

### Getting Started

```Nushell
> $env.STACK_API_KEY="your_app's_key"
> use <path_to>/seAPI *
```

There are two methods:

* `callSeNetworkMethod <path/method> <params>` for network methods. Simple example:

  ```nushell
  > $env.STACK_API_KEY="your_app's_key"

  > use <path_to>/seAPI *
  > callSeNetworkMethod "/sites" { pagesize: 1000 }
  # returns structured table of result to console
  > let sites = (callSeNetworkMethod "/sites" { pagesize: 1000 })
  > $sites.items |
      select name site_url |
      first 5
  ╭───┬─────────────────────┬───────────────────────────────────╮
  │ # │        name         │             site_url              │
  ├───┼─────────────────────┼───────────────────────────────────┤
  │ 0 │ Stack Overflow      │ https://stackoverflow.com         │
  │ 1 │ Server Fault        │ https://serverfault.com           │
  │ 2 │ Super User          │ https://superuser.com             │
  │ 3 │ Meta Stack Exchange │ https://meta.stackexchange.com    │
  │ 4 │ Web Applications    │ https://webapps.stackexchange.com │
  ╰───┴─────────────────────┴───────────────────────────────────╯
  ```


* `callSeSiteMethod <path/method> <site> <params>` for per-site methods.  Simple example:

  ```Nushell
  # How many of the user's last 100 answers were accepted?
  > callSeSiteMethod "users/11810933/answers" |
      get items |
      where is_accepted |
      length
  52
  ```

  Parameterized user using variable interpolation: 
  ```Nushell
  > let userId = 11810933
  > callSeSiteMethod $"users/($userId)/answers" |
      get items |
      where is_accepted |
      length
  52
  ```

Only the first argument is required.  If `site` is omitted for a site call, then `stackoverflow` is assumed.

`params` defaults to a sensible set of params, with:

* Your Stack API key if defined in the `STACK_API_KEY` environment variable.
* A pagesize of 100 records (max for most methods)

You do not need to specify these parameters when overriding the defaults - Your params will be merged into the set.

Example with multiple parameters:

```Nushell
# Find how many times "Jetpack Compose" has been mentioned in answers each year
> 2008..2023 | each {|year|
    let params = {                                                                                                                                                                                               
        filter: "!nNPvSNVZJS",
        pagesize: 0,
        q: $'is:a "Jetpack Compose" created:($year)'
    }
    {
        year: $year,
        totalAnswers: (callSeSiteMethod "/search/excerpts" "stackoverflow" $params).total
    }
  } | to md -p
```

| year | totalAnswers |
| ---- | ------------ |
| 2008 | 0            |
| 2009 | 0            |
| 2010 | 0            |
| 2011 | 0            |
| 2012 | 0            |
| 2013 | 1            |
| 2014 | 1            |
| 2015 | 1            |
| 2016 | 1            |
| 2017 | 0            |
| 2018 | 2            |
| 2019 | 22           |
| 2020 | 70           |
| 2021 | 300          |
| 2022 | 474          |
| 2023 | 306          |
