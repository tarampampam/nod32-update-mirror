package nod32mirror

import (
	"crypto/tls"
	"net/http"
	"nod32-update-mirror/pkg/useragents"
	"strings"
	"time"

	"github.com/go-ini/ini"
)

type Downloader struct {
	httpClient *http.Client
}

type (
	UpdateVer struct {
		Hosts    updateVerHosts
		Sections map[string]updateVerSection
	}

	updateVerHosts struct {
		Other           []string
		PrereleaseOther []string
		DeferredOther   []string
	}

	updateVerSection struct {
		Version      string
		VersionID    uint64
		Build        uint64
		Type         string
		Category     string
		Level        uint64
		Base         uint64
		Date         time.Time
		Platform     string
		Group        []string
		BuildRegName string
		File         string
		Size         uint64
	}
)

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

func (dl *Downloader) ParseUpdateVer(body []byte) (*UpdateVer, error) {
	f, err := ini.Load(body)
	if err != nil {
		return nil, err
	}

	result := UpdateVer{
		Sections: make(map[string]updateVerSection),
	}

	for _, iniSection := range f.Sections() {
		switch iniSectionName := iniSection.Name(); iniSectionName {
		case "HOSTS":
			if iniKey := iniSection.Key("Other"); iniKey != nil {
				result.Hosts.Other = strings.Split(iniKey.String(), ", ")
			}
			if iniKey := iniSection.Key("Prerelease-other"); iniKey != nil {
				result.Hosts.PrereleaseOther = strings.Split(iniKey.String(), ", ")
			}
			if iniKey := iniSection.Key("Deferred-other"); iniKey != nil {
				result.Hosts.DeferredOther = strings.Split(iniKey.String(), ", ")
			}
		default:
			section := updateVerSection{}

			for _, iniKey := range iniSection.Keys() {
				switch iniKey.Name() {
				case "version":
					section.Version = iniKey.String()
				case "versionid":
					if value, err := iniKey.Uint64(); err == nil {
						section.VersionID = value
					}
				case "build":
					if value, err := iniKey.Uint64(); err == nil {
						section.Build = value
					}
				case "type":
					section.Type = iniKey.String()
				case "category":
					section.Category = iniKey.String()
				case "level":
					if value, err := iniKey.Uint64(); err == nil {
						section.Level = value
					}
				case "base":
					if value, err := iniKey.Uint64(); err == nil {
						section.Base = value
					}
				case "date": // `28.05.2019`, <https://golang.org/src/time/format.go>
					if value, err := iniKey.TimeFormat("02.01.2006"); err == nil {
						section.Date = value
					}
				case "platform":
					section.Platform = iniKey.String()
				case "group":
					section.Group = strings.Split(iniKey.String(), ",")
				case "buildregname":
					section.BuildRegName = iniKey.String()
				case "file":
					section.File = iniKey.String()
				case "size":
					if value, err := iniKey.Uint64(); err == nil {
						section.Size = value
					}
				}
			}

			result.Sections[iniSectionName] = section
		}
	}

	return &result, err
}
