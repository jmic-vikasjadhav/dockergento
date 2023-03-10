vcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    if (req.url ~ "\.(png|gif|jpg|swf|css|js)$") {
        unset req.http.Cookie;
        return (hash);
    }
}

sub vcl_backend_response {
    unset beresp.http.Server;
    unset beresp.http.X-Varnish;
    set beresp.ttl = 30m;
}

sub vcl_deliver {
    unset resp.http.Server;
    unset resp.http.X-Powered-By;
}
