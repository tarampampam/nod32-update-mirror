package nod32mirror

import (
	"io/ioutil"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestVersionFile_FromINI(t *testing.T) {
	file, err := os.Open("./testdata/update.ver.ini")
	assert.NoError(t, err)

	body, err := ioutil.ReadAll(file)
	assert.NoError(t, err)
	assert.NoError(t, file.Close())

	u := NewVersionFile()

	assert.Error(t, u.FromINI([]byte("!foobar")))
	assert.NoError(t, u.FromINI(body))

	assert.Equal(t, []string{"10@http://um02.eset.com/eset_upd/", "10@http://185.94.157.10/eset_upd/", "100000@http://update.eset.com/eset_upd/"}, u.Hosts.Other)                                    //nolint:lll
	assert.Equal(t, []string{"10@http://um02.eset.com/eset_upd/pre/", "10@http://185.94.157.10/eset_upd/pre/", "100000@http://update.eset.com/eset_upd/pre/"}, u.Hosts.PrereleaseOther)              //nolint:lll
	assert.Equal(t, []string{"10@http://um02.eset.com/deferred/eset_upd/", "10@http://185.94.157.10/deferred/eset_upd/", "100000@http://update.eset.com/deferred/eset_upd/"}, u.Hosts.DeferredOther) //nolint:lll

	assert.Len(t, u.Sections, 159)

	s := u.Sections["CONTINUOUS_ANTISTEALTH641"]
	assert.Equal(t, "1167 (20200728)", s.Version)
	assert.Equal(t, uint64(1167), s.VersionID)
	assert.Equal(t, uint64(1222), s.Build)
	assert.Equal(t, "antistealth64", s.Type)
	assert.Equal(t, "engine", s.Category)
	assert.Equal(t, uint64(0), s.Level) // empty
	assert.Equal(t, uint64(1221), s.Base)
	assert.Equal(t, time.Date(2020, 7, 28, 0, 0, 0, 0, time.UTC), s.Date)
	assert.Equal(t, "x64", s.Platform)
	assert.Equal(t, []string{"perseus", "win"}, s.Group)
	assert.Equal(t, "Antistealth64Build", s.BuildRegName)
	assert.Equal(t, "/v3-rel-sta/mod_006_antistealth_1222/em006_64_n1.nup", s.File)
	assert.Equal(t, uint64(15745), s.Size)

	s = u.Sections["IRIS1"]
	assert.Equal(t, "1075 (20200929)", s.Version)
	assert.Equal(t, uint64(1075), s.VersionID)
	assert.Equal(t, uint64(1075), s.Build)
	assert.Equal(t, "iris", s.Type)
	assert.Equal(t, "engine", s.Category)
	assert.Equal(t, uint64(1), s.Level)
	assert.Equal(t, uint64(1066), s.Base)
	assert.Equal(t, time.Date(2020, 9, 29, 0, 0, 0, 0, time.UTC), s.Date)
	assert.Equal(t, "x86", s.Platform)
	assert.Equal(t, []string{"iris"}, s.Group)
	assert.Equal(t, "IrisBuild", s.BuildRegName)
	assert.Equal(t, "/v3-rel-sta/mod_024_iris_1075/em024_32_l1.nup", s.File)
	assert.Equal(t, uint64(106339), s.Size)
}
