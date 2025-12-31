#ifndef I2PD_API_H
#define I2PD_API_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * i2pd C API
 * This header provides a C interface for the i2pd library
 * for use with Flutter FFI and other language bindings.
 */

// Initialization
int i2pd_init(const char* config_path);
int i2pd_start(void);
int i2pd_stop(void);
int i2pd_is_running(void);

// Router Information
const char* i2pd_get_router_status(void);
const char* i2pd_get_router_info(void);
int i2pd_get_active_peers(void);
int i2pd_get_known_peers(void);
int i2pd_get_active_tunnels(void);

// Bandwidth Statistics
long i2pd_get_bandwidth_in(void);
long i2pd_get_bandwidth_out(void);
long i2pd_get_transit_bandwidth(void);

// HTTP Proxy
int i2pd_start_http_proxy(int port);
int i2pd_stop_http_proxy(void);

// SOCKS Proxy
int i2pd_start_socks_proxy(int port);
int i2pd_stop_socks_proxy(void);

// Logging
const char* i2pd_get_logs(void);
void i2pd_clear_logs(void);

// Configuration
int i2pd_set_config(const char* key, const char* value);
const char* i2pd_get_config(const char* key);

#ifdef __cplusplus
}
#endif

#endif // I2PD_API_H
