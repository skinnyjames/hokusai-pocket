#ifndef TLSUV_HTTP_SRV_H
#define TLSUV_HTTP_SRV_H

#include <uv.h>
#include <tlsuv/http.h>
#include <tlsuv/tls_link.h>
#include <tlsuv/tls_link.h>
#include <tlsuv/tls_engine.h>

typedef struct tlsuv_http_srv_s tlsuv_http_srv_t;
typedef struct tlsuv_http_srv_conn_s tlsuv_http_srv_conn_t;

// Fired when a full request message (headers + body) is completely parsed and ready
typedef void (*tlsuv_http_srv_req_cb)(tlsuv_http_srv_conn_t *conn, const char *method, const char *path, void *ctx);

struct tlsuv_http_srv_s {
    uv_tcp_t tcp;
    uv_loop_t *loop;
    
    bool is_https;
    tls_context *tls;
    
    tlsuv_http_srv_req_cb req_cb;
    void *ctx;
};

struct tlsuv_http_srv_conn_s {
    tlsuv_http_srv_t *server;
    uv_tcp_t tcp;
    
    uv_link_source_t source_link;
    tls_link_t tls_link;
    uv_link_t http_link;
    
    tlsuv_engine_t engine;
    llhttp_t parser;
    
    // Tracking active parsing state
    char *curr_header_field;
    char *curr_path;
    char *curr_method;

    // Parsed Data Storage
    um_header_list req_headers; 
    char *body;
    size_t body_len;

    bool closing;
};

int tlsuv_http_srv_init(uv_loop_t *loop, tlsuv_http_srv_t *server);
int tlsuv_http_srv_set_cert(tlsuv_http_srv_t *server, const char *cert_path, const char *key_path);
int tlsuv_http_srv_bind(tlsuv_http_srv_t *server, const char *ip, int port);
int tlsuv_http_srv_listen(tlsuv_http_srv_t *server, tlsuv_http_srv_req_cb cb, void *ctx);
int tlsuv_http_srv_stop(tlsuv_http_srv_t *server);

const char* tlsuv_http_srv_get_header(tlsuv_http_srv_conn_t *conn, const char *name);
const char* tlsuv_http_srv_get_body(tlsuv_http_srv_conn_t *conn, size_t *out_len);

// Response Methods
int tlsuv_http_srv_respond(tlsuv_http_srv_conn_t *conn, int status_code, const char *status_msg, const char *body, size_t body_len);

#endif // TLSUV_HTTP_SRV_H