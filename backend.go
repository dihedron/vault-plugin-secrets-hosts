package kv

import (
	"context"

	"github.com/hashicorp/vault/sdk/logical"
)

// Factory will return a logical backend of type versionedKVBackend or
// PassthroughBackend based on the config passed in.
func Factory(ctx context.Context, conf *logical.BackendConfig) (logical.Backend, error) {
	return LeaseSwitchedPassthroughBackend(ctx, conf, conf.Config["leased_passthrough"] == "true")
}
