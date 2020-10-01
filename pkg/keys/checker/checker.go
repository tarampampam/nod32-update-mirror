package checker

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

type Checker struct {
	HTTPClient *http.Client
}

const (
	keyValidationURL     = "http://update.eset.com:80/v8-rel-sta/mod_010_smon_1036/em010_32_l0.nup"
	licenseValidationURL = "https://www.esetnod32.ru/buy/renew/"
)

const (
	browserUserAgent   = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:81.0) Gecko/20100101 Firefox/81.0"                                                                                    //nolint:lll
	nodClientUserAgent = "ESS Update (Windows; U; 32bit; VDB 10000; BPC 6.0.500.0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)" //nolint:lll
)

const (
	defaultHTTPClientTimeout = time.Second * 10
)

func New() Checker {
	return Checker{
		HTTPClient: &http.Client{
			Timeout: defaultHTTPClientTimeout,
		},
	}
}

func (v *Checker) CheckLicense(license string) (bool, error) {
	requestPayload := url.Values{
		"registration_key": {license},
		"action":           {"check"},
	}

	req, err := http.NewRequest(http.MethodPost, licenseValidationURL, strings.NewReader(requestPayload.Encode()))
	if err != nil {
		return false, nil
	}

	req.Header.Set("User-Agent", browserUserAgent)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
	req.Header.Set("Referer", licenseValidationURL)
	req.Header.Set("X-Requested-With", "XMLHttpRequest")

	resp, err := v.HTTPClient.Do(req)
	if err != nil {
		return false, nil
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false, errors.New("wrong server response code (" + strconv.Itoa(resp.StatusCode) + ")")
	}

	content := struct {
		Success bool `json:"success"`
		Error   struct {
			Code interface{} `json:"code"` // string|int
		} `json:"error"`
	}{}

	if err := json.NewDecoder(resp.Body).Decode(&content); err != nil {
		if err == io.EOF {
			return false, errors.New("empty server response (" + licenseValidationURL + ")")
		}

		return false, err
	}

	return content.Success, nil
}

func (v *Checker) CheckKey(id, password string) (bool, error) {
	req, err := http.NewRequest(http.MethodHead, keyValidationURL, nil)
	if err != nil {
		return false, nil
	}

	req.SetBasicAuth(id, password)
	req.Header.Set("User-Agent", nodClientUserAgent)

	resp, err := v.HTTPClient.Do(req)
	if err != nil {
		return false, nil
	}

	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK, nil
}
