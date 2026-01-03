import ballerina/http;
import ballerina/time;

type Target record {|
    string name;
    string baseUrl;
    string path = "/";
    decimal timeoutSeconds = 10;
|};

type MonitorRequest record {|
    Target[] targets;
|};

type TargetResult record {|
    string name;
    string baseUrl;
    string path;
    boolean ok;
    int? statusCode;
    decimal? latencyMs;
    string? 'error;
|};

type MonitorResponse record {|
    string checkedAt;
    int total;
    int up;
    int down;
    TargetResult[] results;
|};

service /monitor on new http:Listener(9090) {

    resource function get ping() returns json {
        return {status: "OK"};
    }

    resource function post 'check(@http:Payload MonitorRequest req)
            returns MonitorResponse|http:BadRequest {

        if req.targets.length() == 0 {
            return <http:BadRequest>{
                body: {message: "targets must not be empty"}
            };
        }

        TargetResult[] results = [];
        int up = 0;
        int down = 0;

        foreach Target t in req.targets {
            TargetResult r = checkTarget(t);
            if r.ok {
                up += 1;
            } else {
                down += 1;
            }
            results.push(r);
        }

        return {
            checkedAt: time:utcToString(time:utcNow()),
            total: results.length(),
            up: up,
            down: down,
            results: results
        };
    }
}

function checkTarget(Target t) returns TargetResult {
    if !t.path.startsWith("/") {
        return {
            name: t.name,
            baseUrl: t.baseUrl,
            path: t.path,
            ok: false,
            statusCode: (),
            latencyMs: (),
            'error: "path must start with '/'"
        };
    }

    http:Client|error tmp = new (t.baseUrl, { timeout: t.timeoutSeconds });

    http:Client httpClient;
    if tmp is http:Client {
        httpClient = tmp;
    } else {
        return {
            name: t.name,
            baseUrl: t.baseUrl,
            path: t.path,
            ok: false,
            statusCode: (),
            latencyMs: (),
            'error: tmp.message()
        };
    }

    decimal startTs = time:monotonicNow();
    http:Response|http:ClientError resp = httpClient->get(t.path);
    decimal endTs = time:monotonicNow();

    decimal latencyMs = (endTs - startTs) * 1000;

    if resp is http:Response {
        int code = resp.statusCode;
        boolean ok = (code >= 200 && code < 400);
        return {
            name: t.name,
            baseUrl: t.baseUrl,
            path: t.path,
            ok: ok,
            statusCode: code,
            latencyMs: latencyMs,
            'error: ()
        };
    }

    return {
        name: t.name,
        baseUrl: t.baseUrl,
        path: t.path,
        ok: false,
        statusCode: (),
        latencyMs: latencyMs,
        'error: resp.message()
    };
}