def if-env [ varname ] {
    if $varname in $env {
        ($env | get $varname )
    } else {
        ""
    }
}

def rootEndpoint [ ] {
    {
        scheme: "https",
        host: "api.stackexchange.com",
        params: {
            key: (if-env STACK_API_KEY),
            access_token: (if-env STACK_ACCESS_TOKEN),
            pagesize: 100
        }
    }
}

export def callSeApi [ 
        path,
        site = "stackoverflow",
        --params (-p) = {},
        --debug (-d),
        --network (-n),
        --POST (-P)
    ] {
    mut endpoint = (rootEndpoint | insert "path" $path)
    
    # Network methods don't have a site parameter
    if $network {
        $endpoint.params = ($endpoint.params | merge $params)
    } else {
        # Merge site first so that it can be overridden by params
        $endpoint.params = ($endpoint.params | merge { site: $site } | merge $params)
    }

    mut res = {}
    loop {
        mut retry = false
        sleep 200ms
        $res = (
            if $POST {
                let params = $endpoint.params
                let endpoint = ($endpoint | reject params)
                let url = ($endpoint | url join)
                if $debug {
                    print $"Endpoint: ($url)"
                    print $"Params: ($params)"
                }
                http post -ef --content-type application/x-www-form-urlencoded $url $params
            } else {
                if $debug {
                    print $"Endpoint: ($endpoint | url join)"
                }
                http get -ef ($endpoint | url join)
            }
        )

        if $res.status != 200 {
            if $res.body.error_id == 407 {
                let backoff = ($res.body.error_message | str replace ".*another ([0-9]+) seconds.*" "$1" | into int) + 1
                sleep ( $"($backoff)sec" | into duration )
                $retry = true
            } else {
                error make --unspanned {
                    msg: ($"($res.body.error_id)" + " (" + $"($res.body.error_name)" + $"): ($res.body.error_message)"),
                }
            }
        }
        if not $retry {
            break
        }
        if $debug {
            print "Retrying..."
        }
    }

    if $debug {
        print $res.headers
        print $"Quota remaining: ($res.body.quota_remaining)"
    }

    if "backoff" in $res.body {
        if $debug {
            print "Backoff: " + $res.body.backoff
        }
        sleep ( $"($res.body.backoff)sec" | into duration )
    }

    $res.body
}

export def --env seSetAccessToken [ scope = "read_inbox,private_info,write_access" ] {
    let state = (random uuid)
    let oauth_params = {
        client_id: $env.STACK_CLIENT_ID,
        scope: $scope,
        redirect_uri: "https://stackoverflow.com/oauth/login_success",
        state: $state
    }
    let url = "https://stackoverflow.com/oauth?" + ($oauth_params | url build-query)
    xdg-open $url
    let redirect_url = (input "Enter the URL you were redirected to: ")

    let res = $redirect_url | url parse | get params
    if $res.state != $state {
        print "State mismatch: " + $res.state + " != " + $state
        exit 1
    }

    let se_post_data = {
        client_id: $env.STACK_CLIENT_ID,
        client_secret: $env.STACK_CLIENT_SECRET,
        code: $res.code,
        redirect_uri: "https://stackoverflow.com/oauth/login_success"
    }
    let res = (http post -f -e --content-type application/x-www-form-urlencoded $"https://stackoverflow.com/oauth/access_token?($se_post_data | url build-query)" '')
    print $res
    $env.STACK_ACCESS_TOKEN = ("https://example.com?" + $res.body | url parse).params.access_token

}