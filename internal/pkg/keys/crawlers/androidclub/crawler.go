package androidclub

import (
	"crypto/tls"
	"log"
	"net/http"
	"nod32-update-mirror/internal/pkg/keys/crawlers"
)

// Crawler is a `https://android-club.ws/` page crawler
type Crawler struct {
	HTTPClient *http.Client
	UserAgent  string
	logger     *log.Logger
}

// NewCrawler creates new crawler for `https://android-club.ws/` page.
func NewCrawler(logger *log.Logger) Crawler {
	return Crawler{
		HTTPClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: true, //nolint:gosec
				},
			},
			Timeout: crawlers.DefaultHTTPRequestTimeout,
		},
		UserAgent: "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3880.4 Safari/537.36", //nolint:lll

		logger: logger, // optional
	}
}
