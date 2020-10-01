package androidclub

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
		assert.Equal(t, "https://android-club.ws/", req.URL.String())
		assert.Equal(t, crawler.UserAgent, req.Header.Get("User-Agent"))

		cwd, err := os.Getwd()
		assert.NoError(t, err)

		file, err := os.Open(cwd + "/testdata/android-club_ws_snapshot.html")
		assert.NoError(t, err)

		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       file,
			Header:     http.Header{},
		}, nil
	})

	res, err := crawler.Fetch()
	assert.NoError(t, err)

	assert.Len(t, *res, 34)

	assert.Contains(t, *res, keys.Key{
		ID:             "BE78-XARD-A2GH-AXEN-NRMF",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeEISv10, keys.KeyTypeEISv11, keys.KeyTypeEISv12},
		ExpiringAtUnix: 1604361600,
	})

	assert.Contains(t, *res, keys.Key{
		ID:             "EAV-08927705",
		Password:       "ut7rpv8mdp",
		Types:          []keys.KeyType{keys.KeyTypeESSv4, keys.KeyTypeESSv5, keys.KeyTypeESSv6, keys.KeyTypeESSv7, keys.KeyTypeESSv8}, //nolint:lll
		ExpiringAtUnix: 1604361600,
	})

	assert.Contains(t, *res, keys.Key{
		ID:             "HVSP-XUV7-8PB7-TWE6-BXRF",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeEAVv9, keys.KeyTypeEAVv10, keys.KeyTypeEAVv11, keys.KeyTypeEAVv12},
		ExpiringAtUnix: 1604361600,
	})
}
