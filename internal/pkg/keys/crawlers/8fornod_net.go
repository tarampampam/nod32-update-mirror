package crawlers

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"nod32-update-mirror/internal/pkg/keys"
	"regexp"
	"strings"
)

// EightForNodDotNetCrawler is a `https://8fornod.net/keys-nod-32-4/` page crawler
type EightForNodDotNetCrawler struct {
	HttpClient *http.Client
	UserAgent  string
}

func NewEightForNodDotNetCrawler() EightForNodDotNetCrawler {
	return EightForNodDotNetCrawler{
		HttpClient: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: true, //nolint:gosec
				},
			},
			Timeout: defaultHttpRequestTimeout,
		},
		UserAgent: "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3880.4 Safari/537.36", //nolint:lll
	}
}

func (c *EightForNodDotNetCrawler) prepareRequest() (*http.Request, error) {
	request, err := http.NewRequest(http.MethodGet, "https://8fornod.net/keys-nod-32-4/", nil)
	if err != nil {
		return nil, err
	}

	request.Header.Set("User-Agent", c.UserAgent)
	request.Header.Set("Referer", "https://8fornod.net/")
	request.Header.Set("Accept", "ext/html,application/xhtml+xml,application/xml;v=b3;q=0.9")

	return request, nil
}

func (c *EightForNodDotNetCrawler) Fetch() (*keys.Keys, error) {
	request, err := c.prepareRequest()

	resp, err := c.HttpClient.Do(request)
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

	if essKeys, err := c.extractESSKeys(content); err == nil && essKeys != nil {
		for _, key := range *essKeys {
			result = append(result, key)
		}
	}

	return &result, nil
}

func (c *EightForNodDotNetCrawler) extractESSKeys(content string) (*keys.Keys, error) {
	// regex: <https://regex101.com/r/3j0kBw/1>
	tbodyRegex, err := regexp.Compile(`(?sU)<tbody[^>]+class="[^"]?keys_ess[^"]?"[^>]?>(.*)<\/tbody>`)
	if err != nil {
		return nil, err
	}

	tbodyMatch := tbodyRegex.FindStringSubmatch(content)

	if len(tbodyMatch) <= 0 {
		return nil, errors.New("cannot extract table content with ESS keys")
	}

	// regex: <https://regex101.com/r/YbZUJq/2>
	keysRegex, err := regexp.Compile(`(?sU)<td[^>]+class="name"[^>]*>(?P<login>[^<]+)</td>\s*<td[^>]+class="password"[^>]*>(?P<password>[^<]+)</td>(\s*<td[^>]+class="dexpired"[^>]*>(?P<expired_at>[^<]+)</td>|)`) //nolint:lll
	if err != nil {
		return nil, err
	}

	keysMatch := keysRegex.FindAllStringSubmatch(strings.Join(tbodyMatch, ""), -1)

	for i, first := range keysMatch {
		for j, second := range first {
			fmt.Println(i, j, second)
		}
	}

//	for i, name := range keysRegex.SubexpNames() {
//		//if i != 0 && name != "" {
//			fmt.Println(i, name, keysMatch[i])
//		//}
//	}
//fmt.Println(keysMatch)

	return nil, nil
}
