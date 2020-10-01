package nod32mirror

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"os"
	"testing"
)

func TestDownloader_ParseUpdateVer(t *testing.T) {
	cwd, err := os.Getwd()
	assert.NoError(t, err)

	file, err := os.Open(cwd + "/testdata/update.ver.ini")
	assert.NoError(t, err)

	body, err := ioutil.ReadAll(file)
	assert.NoError(t, err)
	assert.NoError(t, file.Close())

	dl := NewDownloader()

	res, err := dl.ParseUpdateVer(body)
	assert.NoError(t, err)

	fmt.Printf("%+v/n", res)
}
