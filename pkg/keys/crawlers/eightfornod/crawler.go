package eightfornod

import (
	"crypto/tls"
	"io/ioutil"
	"net/http"
	"nod32-update-mirror/pkg/keys"
	"nod32-update-mirror/pkg/keys/crawlers"
	"nod32-update-mirror/pkg/keys/crawlers/utils"
)

// Crawler is a `https://8fornod.net/keys-nod-32-4/` page crawler
type Crawler struct {
	HTTPClient *http.Client
	UserAgent  string
}

// NewCrawler creates new crawler for `https://8fornod.net/keys-nod-32-4/` page.
func NewCrawler() Crawler {
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
	}
}

// Target return target resource identifier.
func (c Crawler) Target() string {
	return "https://8fornod.net/keys-nod-32-4/"
}

// Fetch extracts keys from target page.
func (c Crawler) Fetch() (*keys.Keys, error) {
	request, err := c.prepareRequest()
	if err != nil {
		return nil, err
	}

	resp, err := c.HTTPClient.Do(request)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	content := string(body)
	result := make(keys.Keys, 0)

	// sources: <view-source:https://8fornod.net/keys-nod-32-4/>
	for tbodyID, keyTypes := range map[string][]keys.KeyType{
		// ESET Smart Security (ESS) 4-8
		"block_keys": {keys.KeyTypeESSv4, keys.KeyTypeESSv5, keys.KeyTypeESSv6, keys.KeyTypeESSv7, keys.KeyTypeESSv8},

		// ESET NOD32 Antivirus (EAV) 4-8
		"block_keys1": {keys.KeyTypeEAVv4, keys.KeyTypeEAVv5, keys.KeyTypeEAVv6, keys.KeyTypeEAVv7, keys.KeyTypeEAVv8},

		// ESET Smart Security (ESS) 9-12
		"block_keys5": {keys.KeyTypeESSv9, keys.KeyTypeESSv10, keys.KeyTypeESSv11, keys.KeyTypeESSv12},

		// ESET NOD32 Antivirus (EAV) 9-12
		"block_keys6": {keys.KeyTypeEAVv9, keys.KeyTypeEAVv10, keys.KeyTypeEAVv11, keys.KeyTypeEAVv12},

		// ESET Internet Security (EIS) 10-12
		"block_keys3": {keys.KeyTypeEISv10, keys.KeyTypeEISv11, keys.KeyTypeEISv12},

		// ESET Smart Security Premium 10-12
		"block_keys4": {keys.KeyTypeEISPv10, keys.KeyTypeEISPv11, keys.KeyTypeEISPv12},
	} {
		if essKeys, err := utils.SimpleTBodyKeysExtract(content, tbodyID, keyTypes); err == nil && essKeys != nil {
			result = append(result, *essKeys...)
		}
	}

	return &result, nil
}

func (c *Crawler) prepareRequest() (*http.Request, error) {
	request, err := http.NewRequest(http.MethodGet, c.Target(), nil)
	if err != nil {
		return nil, err
	}

	request.Header.Set("User-Agent", c.UserAgent)
	request.Header.Set("Referer", c.Target())
	request.Header.Set("Accept", "ext/html,application/xhtml+xml,application/xml;v=b3;q=0.9")

	return request, nil
}
