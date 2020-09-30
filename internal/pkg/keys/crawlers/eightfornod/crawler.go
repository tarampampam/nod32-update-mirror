package eightfornod

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"nod32-update-mirror/internal/pkg/keys"
	"nod32-update-mirror/internal/pkg/keys/crawlers"
	"regexp"
	"strings"
	"time"
)

// Crawler is a `https://8fornod.net/keys-nod-32-4/` page crawler
type Crawler struct {
	HTTPClient *http.Client
	UserAgent  string
	logger     *log.Logger
}

// NewCrawler creates new crawler for `https://8fornod.net/keys-nod-32-4/` page.
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

// Fetch extracts keys from target page.
func (c *Crawler) Fetch() (*keys.Keys, error) {
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
		if essKeys, err := c.extractKeys(content, tbodyID, keyTypes); err == nil && essKeys != nil {
			result = append(result, *essKeys...)
		} else {
			c.log(err)
		}
	}

	return &result, nil
}

func (c *Crawler) log(args ...interface{}) {
	if c.logger != nil {
		c.logger.Println(args...)
	}
}

func (c *Crawler) prepareRequest() (*http.Request, error) {
	request, err := http.NewRequest(http.MethodGet, "https://8fornod.net/keys-nod-32-4/", nil)
	if err != nil {
		return nil, err
	}

	request.Header.Set("User-Agent", c.UserAgent)
	request.Header.Set("Referer", "https://8fornod.net/")
	request.Header.Set("Accept", "ext/html,application/xhtml+xml,application/xml;v=b3;q=0.9")

	return request, nil
}

// regex: <https://regex101.com/r/YbZUJq/3>
var keysRegex = regexp.MustCompile(`(?sU)` + //nolint:gochecknoglobals
	`(<td[^>]+class="name"[^>]*>(?P<login>[^<]+)</td>|)` +
	`\s*<td[^>]+class="password"[^>]*>(?P<password>[^<]+)</td>` +
	`(\s*<td[^>]+class="dexpired"[^>]*>(?P<expired_at>[^<]+)</td>|)`,
)

func (c *Crawler) extractKeys(content, tbodyID string, keyTypes []keys.KeyType) (*keys.Keys, error) {
	// regex: <https://regex101.com/r/3j0kBw/3>
	tableRegex, err := regexp.Compile(fmt.Sprintf(`(?sU)<tbody[^>]+id="[^"]?%s[^"]?"[^>]*>(.*)<\/tbody>`, tbodyID))
	if err != nil {
		return nil, err
	}

	tableMatch := tableRegex.FindStringSubmatch(content)

	if len(tableMatch) == 0 {
		return nil, errors.New("cannot extract table>tbody[id] content with ID " + tbodyID)
	}

	var (
		keysMatch      = keysRegex.FindAllStringSubmatch(tableMatch[1], -1)
		keysRegexNames = keysRegex.SubexpNames()
		result         = make(keys.Keys, 0)
	)

	for _, first := range keysMatch {
		key := keys.Key{Types: keyTypes}

		for j, second := range first {
			if j != 0 && second != "" {
				switch keysRegexNames[j] {
				case "login": // TRIAL-0263727327
					key.ID = strings.TrimSpace(second)
				case "password": // ukc89de2xn or GR65-XK47-7CTV-BX3V-UHCA
					key.Password = strings.TrimSpace(second)
				case "expired_at": // 24.10.2019
					// <https://golang.org/src/time/format.go>
					if t, err := time.Parse("02.01.2006", strings.TrimSpace(second)); err == nil {
						key.ExpiringAtUnix = t.Unix()
					}
				}
			}
		}

		// Rotate key ID and password, if ID is empty (but password exists) - required for LICENSE keys
		if key.ID == "" && key.Password != "" {
			key.ID = key.Password
			key.Password = ""
		}

		if key.ID != "" {
			result = append(result, key)
		}
	}

	if len(result) == 0 {
		return nil, errors.New("keys was not found in a table>tbody[id] with ID " + tbodyID)
	}

	return &result, nil
}
