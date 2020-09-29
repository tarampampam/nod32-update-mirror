package crawlers

import (
	"nod32-update-mirror/internal/pkg/keys"
	"time"
)

type Crawler interface {
	Fetch() (*keys.Keys, error)
}

const defaultHttpRequestTimeout = time.Second * 20
