package crawlers

import (
	"nod32-update-mirror/internal/pkg/keys"
	"time"
)

type Crawler interface {
	// Fetch extracts keys from some resource.
	Fetch() (*keys.Keys, error)

	// Target return target resource identifier.
	Target() string
}

const DefaultHTTPRequestTimeout = time.Second * 10
