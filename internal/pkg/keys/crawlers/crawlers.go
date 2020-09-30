package crawlers

import (
	"nod32-update-mirror/internal/pkg/keys"
	"time"
)

type Crawler interface {
	// Fetch extracts keys from some resource.
	Fetch() (*keys.Keys, error)
}

const DefaultHTTPRequestTimeout = time.Second * 20
