package nod32mirror

import (
	"strings"
	"time"

	"gopkg.in/ini.v1"
)

type (
	VersionFile struct {
		Hosts    versionFileHosts
		Sections map[string]versionFileSection
	}

	versionFileHosts struct {
		Other           []string `ini:"Other"`
		PrereleaseOther []string `ini:"Prerelease-other"`
		DeferredOther   []string `ini:"Deferred-other"`
	}

	versionFileSection struct {
		Version      string    `ini:"version"`
		VersionID    uint64    `ini:"versionid"`
		Build        uint64    `ini:"build"`
		Type         string    `ini:"type"`
		Category     string    `ini:"category"`
		Level        uint64    `ini:"level"`
		Base         uint64    `ini:"base"`
		Date         time.Time `ini:"date"`
		Platform     string    `ini:"platform"`
		Group        []string  `ini:"group"`
		BuildRegName string    `ini:"buildregname"`
		File         string    `ini:"file"`
		Size         uint64    `ini:"size"`
	}
)

// NewVersionFile creates new version file struct.
func NewVersionFile() VersionFile {
	return VersionFile{
		Sections: make(map[string]versionFileSection),
	}
}

// FromINI configure itself using INI file content (file `update.ver`, usually). Content can be string, []byte,
// io.ReadCloser or io.Reader.
func (f *VersionFile) FromINI(content interface{}) (err error) {
	var iniFile *ini.File

	if iniFile, err = ini.Load(content); err != nil {
		return
	}

	for _, iniSection := range iniFile.Sections() {
		switch iniSectionName := iniSection.Name(); iniSectionName {
		case "HOSTS":
			// eg.: `10@http://185.94.157.10/eset_upd/, 100000@http://update.eset.com/eset_upd/`
			if iniKey := iniSection.Key("Other"); iniKey != nil {
				f.Hosts.Other = strings.Split(iniKey.String(), ", ")
			}
			// eg.: `10@http://185.94.157.10/eset_upd/pre/, 100000@http://update.eset.com/eset_upd/pre/`
			if iniKey := iniSection.Key("Prerelease-other"); iniKey != nil {
				f.Hosts.PrereleaseOther = strings.Split(iniKey.String(), ", ")
			}
			// eg.: `10@http://185.94.157.10/deferred/eset_upd/, 100000@http://update.eset.com/deferred/eset_upd/`
			if iniKey := iniSection.Key("Deferred-other"); iniKey != nil {
				f.Hosts.DeferredOther = strings.Split(iniKey.String(), ", ")
			}
		default:
			if iniSectionName == ini.DefaultSection {
				continue
			}

			f.Sections[iniSectionName] = f.parseINISection(iniSection)
		}
	}

	return nil
}

func (f *VersionFile) parseINISection(iniSection *ini.Section) versionFileSection { //nolint:gocyclo
	section := versionFileSection{}

	for _, iniKey := range iniSection.Keys() {
		switch iniKey.Name() {
		case "version": // eg.: `1031 (20190528)`
			section.Version = iniKey.String()
		case "versionid": // eg.: `1031`
			if value, err := iniKey.Uint64(); err == nil {
				section.VersionID = value
			}
		case "build": // eg.: `1032`
			if value, err := iniKey.Uint64(); err == nil {
				section.Build = value
			}
		case "type": // eg.: `perseus`
			section.Type = iniKey.String()
		case "category": // eg.: `engine`
			section.Category = iniKey.String()
		case "level": // eg.: `0`
			if value, err := iniKey.Uint64(); err == nil {
				section.Level = value
			}
		case "base": // eg.: `268435456`
			if value, err := iniKey.Uint64(); err == nil {
				section.Base = value
			}
		case "date": // eg.: `28.05.2019`, <https://golang.org/src/time/format.go>
			if value, err := iniKey.TimeFormat("02.01.2006"); err == nil {
				section.Date = value
			}
		case "platform": // eg.: `x86`
			section.Platform = iniKey.String()
		case "group": // eg.: `perseus,ra,core,eslc`
			section.Group = strings.Split(iniKey.String(), ",")
		case "buildregname": // eg.: `PerseusBuild`
			section.BuildRegName = iniKey.String()
		case "file": // eg.: `/v3-rel-sta/mod_001_perseus_2121/em001_32_l0.nup`
			section.File = iniKey.String()
		case "size": // eg.: `1220743`
			if value, err := iniKey.Uint64(); err == nil {
				section.Size = value
			}
		}
	}

	return section
}
