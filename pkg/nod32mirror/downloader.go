package nod32mirror

import (
	"crypto/tls"
	"net/http"
	"nod32-update-mirror/pkg/useragents"
	"strings"
)

type Downloader struct {
	httpClient *http.Client
}

func NewDownloader() Downloader {
	return Downloader{
		httpClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: true, //nolint:gosec
				},
			},
		},
	}
}

// CheckServer for server availability (URI must looks like `http(s)://{host}/{eset_upd|another_path}/`).
func (dl *Downloader) CheckServer(serverURI string) (bool, error) {
	req, err := http.NewRequest(http.MethodHead, strings.TrimRight(serverURI, "/")+"/update.ver", nil)
	if err != nil {
		return false, nil
	}

	req.Header.Set("User-Agent", useragents.Nod32Client())

	resp, err := dl.httpClient.Do(req)
	if err != nil {
		return false, nil
	}

	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK, nil
}
