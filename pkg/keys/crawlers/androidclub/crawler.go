package androidclub

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"nod32-update-mirror/pkg/keys"
	"nod32-update-mirror/pkg/keys/crawlers"
	"nod32-update-mirror/pkg/keys/crawlers/utils"
	"nod32-update-mirror/pkg/useragents"
	"regexp"
	"strings"
	"time"
)

// Crawler is a `https://android-club.ws/` page crawler
type Crawler struct {
	HTTPClient *http.Client
	UserAgent  string
}

// NewCrawler creates new crawler for `https://android-club.ws/` page.
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
		UserAgent: useragents.GoogleChrome(),
	}
}

// Target return target resource identifier.
func (c Crawler) Target() string {
	return "https://android-club.ws/"
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

	// sources: <view-source:https://android-club.ws/>
	for tbodyID, keyTypes := range map[string][]keys.KeyType{
		// ESET Internet Security (EIS) 10-12
		"block_keys3": {keys.KeyTypeEISv10, keys.KeyTypeEISv11, keys.KeyTypeEISv12},

		// ESET Smart Security Premium 10-12
		"block_keys4": {keys.KeyTypeESSPv10, keys.KeyTypeESSPv11, keys.KeyTypeESSPv12},
	} {
		if essKeys, err := utils.SimpleTBodyKeysExtract(content, tbodyID, keyTypes); err == nil && essKeys != nil {
			result = append(result, *essKeys...)
		}
	}

	if extractedKeys, err := c.extractESS4to13keys(content); err == nil && extractedKeys != nil {
		result = append(result, *extractedKeys...)
	}

	if extractedKeys, err := c.extractEAV4to12keys(content); err == nil && extractedKeys != nil {
		result = append(result, *extractedKeys...)
	}

	// extract expiring from page and update all extracted keys
	if exp, err := c.extractExpiringAtUnix(content); err == nil && len(result) > 0 {
		for i := 0; i < len(result); i++ {
			result[i].ExpiringAtUnix = exp
		}
	}

	return &result, nil
}

func (c *Crawler) prepareRequest() (*http.Request, error) {
	request, err := http.NewRequest(http.MethodGet, "https://android-club.ws/", nil)
	if err != nil {
		return nil, err
	}

	request.Header.Set("User-Agent", c.UserAgent)
	request.Header.Set("Accept", "ext/html,application/xhtml+xml,application/xml;v=b3;q=0.9")

	return request, nil
}

func (c *Crawler) extractExpiringAtUnix(content string) (int64, error) {
	expRegex := regexp.MustCompile(`действительны до (\d+.\d+.\d+)`)
	match := expRegex.FindStringSubmatch(content)

	if len(match) == 0 {
		return 0, errors.New("required pattern was not found")
	}

	t, err := time.Parse("02.01.2006", match[1])
	if err != nil {
		return 0, err
	}

	return t.Unix(), nil
}

func (c *Crawler) extractEAV4to12keys(content string) (*keys.Keys, error) {
	const tbodyID = "block_keys1"

	// regex: <https://regex101.com/r/3j0kBw/3>
	tbodyRegex := regexp.MustCompile(fmt.Sprintf(`(?sU)<tbody[^>]+id="[^"]?%s[^"]?"[^>]*>(.*)<\/tbody>`, tbodyID))
	tbodyMatch := tbodyRegex.FindStringSubmatch(content)

	if len(tbodyMatch) == 0 {
		return nil, errors.New("cannot extract table>tbody[id] content with ID " + tbodyID)
	}

	result := make(keys.Keys, 0)

	// extract ESS v4..v8 keys
	result = append(result, c.extractKeysFromTBody(tbodyMatch[1], []keys.KeyType{
		keys.KeyTypeEAVv4, keys.KeyTypeEAVv5, keys.KeyTypeEAVv6, keys.KeyTypeEAVv7, keys.KeyTypeEAVv8,
	})...)

	// extract ESS v9..v13 keys
	result = append(result, c.extractLicensesFromTBody(tbodyMatch[1], []keys.KeyType{
		keys.KeyTypeEAVv9, keys.KeyTypeEAVv10, keys.KeyTypeEAVv11, keys.KeyTypeEAVv12,
	})...)

	return &result, nil
}

func (c *Crawler) extractESS4to13keys(content string) (*keys.Keys, error) {
	const tbodyID = "block_keys"

	// regex: <https://regex101.com/r/3j0kBw/3>
	tbodyRegex := regexp.MustCompile(fmt.Sprintf(`(?sU)<tbody[^>]+id="[^"]?%s[^"]?"[^>]*>(.*)<\/tbody>`, tbodyID))
	tbodyMatch := tbodyRegex.FindStringSubmatch(content)

	if len(tbodyMatch) == 0 {
		return nil, errors.New("cannot extract table>tbody[id] content with ID " + tbodyID)
	}

	result := make(keys.Keys, 0)

	// extract ESS v4..v8 keys
	result = append(result, c.extractKeysFromTBody(tbodyMatch[1], []keys.KeyType{
		keys.KeyTypeESSv4, keys.KeyTypeESSv5, keys.KeyTypeESSv6, keys.KeyTypeESSv7, keys.KeyTypeESSv8,
	})...)

	// extract ESS v9..v13 keys
	result = append(result, c.extractLicensesFromTBody(tbodyMatch[1], []keys.KeyType{
		keys.KeyTypeESSv9, keys.KeyTypeESSv10, keys.KeyTypeESSv11, keys.KeyTypeESSv12, keys.KeyTypeESSv13,
	})...)

	return &result, nil
}

func (c *Crawler) extractKeysFromTBody(content string, keyTypes []keys.KeyType) keys.Keys {
	result := make(keys.Keys, 0)

	var (
		// regex: <https://regex101.com/r/aV9hGR/1>
		ess4to8Regex          = regexp.MustCompile(`(?U)<td[^>]+class="name"[^>]*>(?P<login>[^<]+)</td>\s*<td[^>]+class="password"[^>]*>(?P<password>[^<]+)</td>`) //nolint:lll
		ess4to8KeysMatch      = ess4to8Regex.FindAllStringSubmatch(content, -1)
		ess4to8KeysRegexNames = ess4to8Regex.SubexpNames()
	)

	for _, first := range ess4to8KeysMatch {
		key := keys.Key{Types: keyTypes}

		for j, second := range first {
			if j != 0 && second != "" {
				switch ess4to8KeysRegexNames[j] {
				case "login": // TRIAL-0263727327
					key.ID = strings.TrimSpace(second)
				case "password": // ukc89de2xn
					key.Password = strings.TrimSpace(second)
				}
			}
		}

		if key.ID != "" && key.Password != "" {
			result = append(result, key)
		}
	}

	return result
}

func (c *Crawler) extractLicensesFromTBody(content string, keyTypes []keys.KeyType) keys.Keys {
	result := make(keys.Keys, 0)

	ess9to13KeysMatch := regexp. // regex: <https://regex101.com/r/RMXLtl/1/>
					MustCompile(`<td[^>]+id="[^"]+(smart|bigcode)[^"]+"[^>]+class="password"[^>]*>([^<]+)</td>`).
					FindAllStringSubmatch(content, -1)

	for _, first := range ess9to13KeysMatch {
		for j, second := range first {
			if j == 2 && second != "" {
				result = append(result, keys.Key{
					Types: keyTypes,
					ID:    strings.TrimSpace(second),
				})
			}
		}
	}

	return result
}
