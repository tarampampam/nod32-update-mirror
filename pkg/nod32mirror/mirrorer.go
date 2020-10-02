package nod32mirror

import (
	"crypto/tls"
	"errors"
	"net/http"
	"nod32-update-mirror/pkg/useragents"
	"strconv"
	"time"
)

type Mirrorer struct {
	HTTPClient *http.Client
}

const defaultHTTPTimeout = time.Second * 20

func NewMirrorer() *Mirrorer {
	return &Mirrorer{
		HTTPClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: true, //nolint:gosec
				},
			},
			Timeout: defaultHTTPTimeout,
		},
	}
}

// GetRemoteVersionFile downloads and parse versions file from remote server.
func (m *Mirrorer) GetRemoteVersionFile(fileURI string) (*VersionFile, error) {
	req, err := http.NewRequest(http.MethodGet, fileURI, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("User-Agent", useragents.Nod32Client())

	resp, err := m.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, errors.New("wrong server response code (" + strconv.Itoa(resp.StatusCode) + ")")
	}

	// @todo: file can be packed using RAR. so, add here checking for this and unpacking

	file := NewVersionFile()
	if err := file.FromINI(resp.Body); err != nil {
		return nil, err
	}

	return &file, nil
}
