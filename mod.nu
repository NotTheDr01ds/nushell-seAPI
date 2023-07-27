
def rootEndpoint [ ] {
    let key = (
        if 'STACK_API_KEY' in $env {
            $env.STACK_API_KEY
        } else {
            ""
        }
    )

    {
        scheme: "https",
        host: "api.stackexchange.com",
        params: {
            key: $key,
            pagesize: 100
        }
    }
}

export def callSeNetworkMethod [ path, params = {} ] {
    mut endpoint = (rootEndpoint | insert "path" $path)
    $endpoint.params = ($endpoint.params | merge $params) 
    callSeApiMethod $endpoint
}

export def callSeSiteMethod [ path, site = "stackoverflow", params:record = {} ] {
    mut endpoint = (rootEndpoint | insert "path" $path)
    # Merge site first so that it can be overridden by params
    $endpoint.params = ($endpoint.params | merge { site: $site } | merge $params)
    callSeApiMethod $endpoint
}

def callSeApiMethod [ endpoint: record ] {
    let res = (http get ($endpoint | url join))
    if "backoff" in $res {
        print "Backoff: " + $res.backoff
        sleep ( $"($res.backoff)sec" | into duration )
    }

    $res
}