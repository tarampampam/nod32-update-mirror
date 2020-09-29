package crawlers

import (
	"github.com/stretchr/testify/assert"
	"net/http"
	"os"
	"testing"
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

func TestEightForNodDotNetCrawler_Fetch(t *testing.T) {
	crawler := NewEightForNodDotNetCrawler()

	crawler.HttpClient = newTestClient(func(req *http.Request) (*http.Response, error) {
		assert.Equal(t, "https://8fornod.net/keys-nod-32-4/", req.URL.String())
		assert.Equal(t, crawler.UserAgent, req.Header.Get("User-Agent"))

		cwd, err := os.Getwd()
		assert.NoError(t, err)

		file, err := os.Open(cwd + "/8fornod_net_response_for_test.html")
		assert.NoError(t, err)

		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       file,
			Header:     http.Header{},
		}, nil
	})

	crawler.Fetch()
}
