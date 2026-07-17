#ifndef TLSUV_HTTP_SRV
#define TLSUV_HTTP_SRV

#include "patch.h"
#include <string.h>
#include <stdlib.h>

#define UM_LOG(level, fmt, ...) fprintf(stderr, "[" #level "] " fmt "\n", ##__VA_ARGS__)
extern tls_context *get_default_tls(void);

// ============================================================================
// llhttp Request Parser Callbacks
// ============================================================================

static int srv_on_message_begin(llhttp_t *p) { 
    return 0; 
}

static int srv_on_url(llhttp_t *p, const char *at, size_t len) {
    tlsuv_http_srv_conn_t *conn = p->data;

    // Custom inline strndup using standard malloc/memcpy
    conn->curr_path = malloc(len + 1);
    if (conn->curr_path) {
        memcpy(conn->curr_path, at, len);
        conn->curr_path[len] = '\0';
    }
    
    conn->curr_method = strdup(llhttp_method_name(p->method));
    return 0;
}

static int srv_on_header_field(llhttp_t *p, const char *at, size_t len) {
    tlsuv_http_srv_conn_t *conn = p->data;
    
    conn->curr_header_field = malloc(len + 1);
    if (conn->curr_header_field) {
        memcpy(conn->curr_header_field, at, len);
        conn->curr_header_field[len] = '\0';
    }
    return 0;
}

static int srv_on_header_value(llhttp_t *p, const char *at, size_t len) {
    tlsuv_http_srv_conn_t *conn = p->data;
    
    if (len > 0 && conn->curr_header_field) {

      // Allocate a new header container node matching tlsuv's internal structure layout
      struct tlsuv_http_hdr_s *h = malloc(sizeof(struct tlsuv_http_hdr_s));
      if (h) {
          // Duplicate the field name string we saved previously
          h->name = strdup(conn->curr_header_field);
          
          // Safely duplicate the incoming header value segment using your buffer bounds
          h->value = malloc(len + 1);
          if (h->value) {
              memcpy(h->value, at, len);
              h->value[len] = '\0';
          }
          
          // Inject the fully built token directly into your tracking linked-list
          LIST_INSERT_HEAD(&conn->req_headers, h, _next);
      }

      // Clean up your field name tracker scratch-pad for the next incoming header field
      free(conn->curr_header_field);
      conn->curr_header_field = NULL;
    }
    
    if (conn->curr_header_field) {
        free(conn->curr_header_field);
        conn->curr_header_field = NULL;
    }
    return 0;
}

static int srv_on_body(llhttp_t *p, const char *at, size_t len) {
    tlsuv_http_srv_conn_t *conn = p->data;
    
    char *new_body = realloc(conn->body, conn->body_len + len + 1);
    if (!new_body) {
        return HPE_INTERNAL;
    }
    
    conn->body = new_body;
    memcpy(conn->body + conn->body_len, at, len);
    conn->body_len += len;
    conn->body[conn->body_len] = '\0';
    
    return 0;
}

static int srv_on_message_complete(llhttp_t *p) {
    tlsuv_http_srv_conn_t *conn = p->data;
    if (conn->server->req_cb) {
        conn->server->req_cb(conn, conn->curr_method, conn->curr_path, conn->server->ctx);
    }

    return 0;
}

static llhttp_settings_t SERVER_HTTP_PROC = {
    .on_message_begin = srv_on_message_begin,
    .on_url = srv_on_url,
    .on_header_field = srv_on_header_field,
    .on_header_value = srv_on_header_value,
    .on_body = srv_on_body,
    .on_message_complete = srv_on_message_complete
};

// ============================================================================
// Pipeline Lifecycle & Connection Processing
// ============================================================================
static void free_server_conn(uv_link_t *link) {
    tlsuv_http_srv_conn_t *conn = link->data;
    
    if (conn->engine) {
      (conn->engine)->free(conn->engine);
    }

    // Server-wide cert/key (set via tlsuv_http_srv_set_cert) live inside
    // the shared tls_context, not per-connection state -- nothing to free
    // here for them; tls_context's own free_ctx handles that lifecycle.

    struct tlsuv_http_hdr_s *h;
    while (!LIST_EMPTY(&conn->req_headers)) {
        h = LIST_FIRST(&conn->req_headers);
        LIST_REMOVE(h, _next);
        if (h->name) free(h->name);
        if (h->value) free(h->value);
        free(h);
    }

    if (conn->body) free(conn->body);
    if (conn->curr_path) free(conn->curr_path);
    if (conn->curr_method) free(conn->curr_method);
    if (conn->curr_header_field) free(conn->curr_header_field);
    
    free(conn);
}

static void srv_link_close_cb(uv_link_t *link) {
    free_server_conn(link);
}

static void srv_read_cb(uv_link_t *link, ssize_t nread, const uv_buf_t *buf) {
    tlsuv_http_srv_conn_t *conn = link->data;

    // Once an error has tripped (or a close is otherwise underway), never
    // call llhttp_execute again on this parser -- uv_link_close below is
    // asynchronous, so more buffered data can still arrive and fire this
    // callback again before that close actually completes. Feeding an
    // already-errored llhttp parser more data is undefined behavior on
    // llhttp's side, not just ours, and is what was crashing.
    if (conn->closing) {
        if (buf && buf->base) free(buf->base);
        return;
    }

    if (nread > 0) {
        llhttp_errno_t err = llhttp_execute(&conn->parser, buf->base, nread);
        if (err != HPE_OK) {
            UM_LOG(ERR, "Server HTTP parse failure: %s", llhttp_errno_name(err));
            conn->closing = true;
            uv_link_close(link, srv_link_close_cb);
        }
    } else {
        // EOF or error received, tear down client pipeline
        conn->closing = true;
        uv_link_close(link, srv_link_close_cb);
    }

    if (buf && buf->base) free(buf->base);
}

static const uv_link_methods_t srv_http_link_methods = {
    .close = uv_link_default_close,
    .read_start = uv_link_default_read_start,
    .write = uv_link_default_write,
    .alloc_cb_override = uv_link_default_alloc_cb_override,
    .read_cb_override = srv_read_cb
};

static void on_srv_tls_handshake(tls_link_t *tls, int status) {
    tlsuv_http_srv_conn_t *conn = tls->data;
    if (status == TLS_HS_COMPLETE) {
        uv_link_read_start(&conn->http_link);
    } else {
        UM_LOG(ERR, "Server TLS Handshake failed.");
        uv_link_close((uv_link_t*)&conn->tls_link, srv_link_close_cb);
    }
}

static void on_new_connection(uv_stream_t *server_stream, int status) {
    if (status < 0) return;

    tlsuv_http_srv_t *server = (tlsuv_http_srv_t*)server_stream->data;
    tlsuv_http_srv_conn_t *conn = calloc(1, sizeof(tlsuv_http_srv_conn_t));
    conn->server = server;
    conn->closing = false;
    
    LIST_INIT(&conn->req_headers);

    uv_tcp_init(server->loop, &conn->tcp);
    if (uv_accept(server_stream, (uv_stream_t*)&conn->tcp) != 0) {
        free(conn);
        return;
    }

    // Initialize as an incoming HTTP_REQUEST parser context
    llhttp_init(&conn->parser, HTTP_REQUEST, &SERVER_HTTP_PROC);
    conn->parser.data = conn;

    uv_link_source_init(&conn->source_link, (uv_stream_t*)&conn->tcp);
    conn->source_link.data = conn;

    uv_link_init(&conn->http_link, &srv_http_link_methods);
    conn->http_link.data = conn;

    if (server->is_https) {
        conn->engine = server->tls->new_engine(server->tls, NULL);
        tlsuv_tls_link_init(&conn->tls_link, conn->engine, on_srv_tls_handshake);
        conn->tls_link.data = conn;

        uv_link_chain((uv_link_t*)&conn->source_link, (uv_link_t*)&conn->tls_link);
        uv_link_chain((uv_link_t*)&conn->tls_link, &conn->http_link);
        
        uv_link_read_start((uv_link_t*)&conn->tls_link);
    } else {
        uv_link_chain((uv_link_t*)&conn->source_link, &conn->http_link);
        uv_link_read_start(&conn->http_link);
    }
}

// ============================================================================
// Public Consumer API
// ============================================================================

int tlsuv_http_srv_init(uv_loop_t *loop, tlsuv_http_srv_t *server) {
    if (!loop || !server) return UV_EINVAL;
    memset(server, 0, sizeof(tlsuv_http_srv_t));
    server->loop = loop;
    server->tcp.data = server;
    server->is_https = false;
    return uv_tcp_init(loop, &server->tcp);
}

int tlsuv_http_srv_set_cert(tlsuv_http_srv_t *server, const char *cert_path, const char *key_path) {
    if (!server || !cert_path || !key_path) return UV_EINVAL;

    // Deliberately NOT get_default_tls() here: that returns a process-wide
    // singleton shared by every tlsuv consumer that doesn't pass its own
    // tls_context (e.g. any client-side Hokusai::Request in http.c).
    // Calling set_own_cert on the shared default would mean this server's
    // cert/key gets presented on unrelated outbound client HTTPS
    // connections too. default_tls_context(...) gives this server its own
    // independent context instead.
    server->tls = default_tls_context(NULL, 0);
    if (!server->tls) return UV_ENOMEM;

    tls_context *ctx = server->tls;

    // load_cert/load_key both accept either an in-memory PEM buffer or a
    // file path (they try PEM parse first, then fall back to treating the
    // buffer as a path) -- passing cert_path/key_path directly, the same
    // way the rest of tlsuv's own callers do, rather than hand-parsing
    // mbedTLS structures ourselves.
    tlsuv_certificate_t cert = NULL;
    int rc = ctx->load_cert(&cert, cert_path, strlen(cert_path));
    if (rc != 0 || !cert) {
        UM_LOG(ERR, "Failed to load server certificate from %s", cert_path);
        return UV_EINVAL;
    }

    tlsuv_private_key_t key = NULL;
    rc = ctx->load_key(&key, key_path, strlen(key_path));
    if (rc != 0 || !key) {
        UM_LOG(ERR, "Failed to load server private key from %s", key_path);
        cert->free(cert);
        return UV_EINVAL;
    }

    // Binds key+cert onto the context; every engine ctx->new_engine()
    // creates afterwards (i.e. every accepted connection) picks these up
    // automatically. The context itself (and the cert/key it now owns)
    // gets torn down as a unit via ctx->free_ctx() in tlsuv_http_srv_stop.
    rc = ctx->set_own_cert(ctx, key, cert);
    if (rc != 0) {
        UM_LOG(ERR, "Failed to set server certificate/key on TLS context");
        return UV_EINVAL;
    }

    server->is_https = true;
    UM_LOG(INFO, "Server TLS context successfully configured for server mode.");
    return 0;
}

int tlsuv_http_srv_bind(tlsuv_http_srv_t *server, const char *ip, int port) {
    struct sockaddr_in addr;
    int rc = uv_ip4_addr(ip, port, &addr);
    if (rc != 0) return rc;
    return uv_tcp_bind(&server->tcp, (const struct sockaddr*)&addr, 0);
}

int tlsuv_http_srv_listen(tlsuv_http_srv_t *server, tlsuv_http_srv_req_cb cb, void *ctx) {
    if (!server || !cb) return UV_EINVAL;
    server->req_cb = cb;
    server->ctx = ctx;
    return uv_listen((uv_stream_t*)&server->tcp, 128, on_new_connection);
}

int tlsuv_http_srv_stop(tlsuv_http_srv_t *server) {
    if (!server) return UV_EINVAL;
    if (server->is_https && server->tls) {
        server->tls->free_ctx(server->tls);
        server->tls = NULL;
    }

    if (!uv_is_closing((uv_handle_t*)&server->tcp)) {
        uv_close((uv_handle_t*)&server->tcp, NULL);
        return 0;
    }
    return UV_EINVAL;
}

const char* tlsuv_http_srv_get_header(tlsuv_http_srv_conn_t *conn, const char *name) {
    tlsuv_http_hdr *h;
    LIST_FOREACH(h, &conn->req_headers, _next) {
        if (strcasecmp(h->name, name) == 0) {
            return h->value;
        }
    }
    return NULL;
}

const char* tlsuv_http_srv_get_body(tlsuv_http_srv_conn_t *conn, size_t *out_len) {
    if (out_len) *out_len = conn->body_len;
    return conn->body ? conn->body : "";
}

static void on_srv_write_cb(uv_link_t *link, int status, void *data) {
    free(data); // Free the combined response allocation
    uv_link_close(link, srv_link_close_cb); // Force end connection after responding
}

int tlsuv_http_srv_respond(tlsuv_http_srv_conn_t *conn, int status_code, const char *status_msg, const char *body, size_t body_len) {
    char *resp_buf = malloc(4096 + body_len);
    if (!resp_buf) return UV_ENOMEM;

    int head_len = snprintf(resp_buf, 4096,
        "HTTP/1.1 %d %s\r\n"
        "Content-Length: %zd\r\n"
        "Connection: close\r\n\r\n", 
        status_code, status_msg, body_len);

    if (body && body_len > 0) {
        memcpy(resp_buf + head_len, body, body_len);
    }

    uv_buf_t buf = uv_buf_init(resp_buf, head_len + body_len);
    return uv_link_write(&conn->http_link, &buf, 1, NULL, on_srv_write_cb, resp_buf);
}

#endif