package eightfornod

import (
	"net/http"
	"nod32-update-mirror/pkg/keys"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

type roundTripFunc func(req *http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

// newTestClient returns *http.Client with Transport replaced to avoid making real calls.
func newTestClient(fn roundTripFunc) *http.Client {
	return &http.Client{
		Transport: roundTripFunc(fn), //nolint:unconvert
	}
}

func TestCrawler_Fetch(t *testing.T) {
	crawler := NewCrawler()

	crawler.HTTPClient = newTestClient(func(req *http.Request) (*http.Response, error) {
		assert.Equal(t, "https://8fornod.net/keys-nod-32-4/", req.URL.String())
		assert.Equal(t, crawler.UserAgent, req.Header.Get("User-Agent"))

		cwd, err := os.Getwd()
		assert.NoError(t, err)

		file, err := os.Open(cwd + "/testdata/8fornod_net_snapshot.html")
		assert.NoError(t, err)

		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       file,
			Header:     http.Header{},
		}, nil
	})

	res, err := crawler.Fetch()
	assert.NoError(t, err)

	assert.Len(t, *res, 32)

	assert.Contains(t, *res, keys.Key{
		ID:             "EAV-0264051918",
		Password:       "fuk6c2t7v2",
		Types:          []keys.KeyType{keys.KeyTypeESSv4, keys.KeyTypeESSv5, keys.KeyTypeESSv6, keys.KeyTypeESSv7, keys.KeyTypeESSv8}, //nolint:lll
		ExpiringAtUnix: 1572480000,
	})

	assert.Contains(t, *res, keys.Key{
		ID:             "CC66-XA55-MBCM-N9NE-PAA8",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeESSv9, keys.KeyTypeESSv10, keys.KeyTypeESSv11, keys.KeyTypeESSv12},
		ExpiringAtUnix: 1576368000,
	})

	assert.Contains(t, *res, keys.Key{
		ID:             "CWSW-XDVT-XMG9-WBR4-RJTV",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeEISPv10, keys.KeyTypeEISPv11, keys.KeyTypeEISPv12},
		ExpiringAtUnix: 1571875200,
	})
}
