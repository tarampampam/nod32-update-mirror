package utils

import (
	"errors"
	"fmt"
	"nod32-update-mirror/internal/pkg/keys"
	"regexp"
	"strings"
	"time"
)

// regex: <https://regex101.com/r/YbZUJq/3>
var simpleTBodyKeysRegex = regexp.MustCompile(`(?sU)` + //nolint:gochecknoglobals
	`(<td[^>]+class="name"[^>]*>(?P<login>[^<]+)</td>|)` +
	`\s*<td[^>]+class="password"[^>]*>(?P<password>[^<]+)</td>` +
	`(\s*<td[^>]+class="dexpired"[^>]*>(?P<expired_at>[^<]+)</td>|)`,
)

// SimpleTBodyKeysExtract can extract ESET Nod32 keys (or licenses) from HTML table content, where `<tbody id="..">`
// ID is fixed, and keys HTML markup uses CSS classes like `name`, `password` and `dexpired`. For more usage examples
// watch for this function tests.
func SimpleTBodyKeysExtract(content, tbodyID string, keyTypes []keys.KeyType) (*keys.Keys, error) {
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
		keysMatch      = simpleTBodyKeysRegex.FindAllStringSubmatch(tableMatch[1], -1)
		keysRegexNames = simpleTBodyKeysRegex.SubexpNames()
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
