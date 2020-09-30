package keepers

import (
	"io/ioutil"
	"nod32-update-mirror/internal/pkg/keys"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestInMemoryKeeper_Add(t *testing.T) {
	keeper := NewInMemoryKeeper()
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	assert.NoError(t, keeper.Add(giveKey))

	gotKey, err := keeper.Get(giveKey.ID)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, *gotKey)
}

func TestInMemoryKeeper_All(t *testing.T) {
	keeper := NewInMemoryKeeper()
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	gotAll, err := keeper.All()
	assert.NoError(t, err)
	assert.Empty(t, *gotAll)

	assert.NoError(t, keeper.Add(giveKey))

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 1)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, (*gotAll)[0])

	// key with same ID must be overwritten
	assert.NoError(t, keeper.Add(keys.Key{ID: "foo"}))

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 1)
	assert.NoError(t, err)

	assert.NoError(t, keeper.Add(keys.Key{ID: "bar", Password: "baz"}))

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 2)
	assert.NoError(t, err)
}

func TestInMemoryKeeper_Clear(t *testing.T) {
	keeper := NewInMemoryKeeper()

	assert.NoError(t, keeper.Clear())

	assert.NoError(t, keeper.Add(keys.Key{ID: "foo"}))

	gotAll, _ := keeper.All()
	assert.NotEmpty(t, gotAll)

	assert.NoError(t, keeper.Clear())

	gotAll, _ = keeper.All()
	assert.Empty(t, gotAll)
}

func TestInMemoryKeeper_Get(t *testing.T) {
	keeper := NewInMemoryKeeper()
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	gotKey, err := keeper.Get(giveKey.ID)
	assert.Error(t, err)
	assert.Nil(t, gotKey)

	assert.NoError(t, keeper.Add(giveKey))

	gotKey, err = keeper.Get(giveKey.ID)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, *gotKey)
}

func TestInMemoryKeeper_Remove(t *testing.T) {
	keeper := NewInMemoryKeeper()
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	assert.Error(t, keeper.Remove(giveKey.ID))
	assert.NoError(t, keeper.Add(giveKey))
	assert.NoError(t, keeper.Remove(giveKey.ID))
}

func TestFileKeeper_Add(t *testing.T) {
	tmpDir := createTempDir(t)
	defer removeTempDir(t, tmpDir)

	filePath := tmpDir + "/test.json"
	keeper := NewFileKeeper(filePath)
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	assert.NoError(t, keeper.Add(giveKey))

	gotKey, err := keeper.Get(giveKey.ID)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, *gotKey)

	// re-create instance
	keeper = NewFileKeeper(filePath)

	gotKey, err = keeper.Get(giveKey.ID)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, *gotKey)
}

func TestFileKeeper_All(t *testing.T) {
	tmpDir := createTempDir(t)
	defer removeTempDir(t, tmpDir)

	filePath := tmpDir + "/test.json"
	keeper := NewFileKeeper(filePath)
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	gotAll, err := keeper.All()
	assert.NoError(t, err)
	assert.Empty(t, *gotAll)

	assert.NoError(t, keeper.Add(giveKey))

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 1)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, (*gotAll)[0])

	// key with same ID must be overwritten
	assert.NoError(t, keeper.Add(keys.Key{ID: "foo"}))

	// re-create instance
	keeper = NewFileKeeper(filePath)

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 1)
	assert.NoError(t, err)

	assert.NoError(t, keeper.Add(keys.Key{ID: "bar", Password: "baz"}))

	gotAll, err = keeper.All()
	assert.Len(t, *gotAll, 2)
	assert.NoError(t, err)
}

func TestFileKeeper_Clear(t *testing.T) {
	tmpDir := createTempDir(t)
	defer removeTempDir(t, tmpDir)

	keeper := NewFileKeeper(tmpDir + "/test.json")

	assert.NoError(t, keeper.Clear())

	assert.NoError(t, keeper.Add(keys.Key{ID: "foo"}))

	gotAll, _ := keeper.All()
	assert.NotEmpty(t, gotAll)

	assert.NoError(t, keeper.Clear())

	gotAll, _ = keeper.All()
	assert.Empty(t, gotAll)
}

func TestFileKeeper_Get(t *testing.T) {
	tmpDir := createTempDir(t)
	defer removeTempDir(t, tmpDir)

	filePath := tmpDir + "/test.json"
	keeper := NewFileKeeper(filePath)
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	gotKey, err := keeper.Get(giveKey.ID)
	assert.Error(t, err)
	assert.Nil(t, gotKey)

	assert.NoError(t, keeper.Add(giveKey))

	// re-create instance
	keeper = NewFileKeeper(filePath)

	gotKey, err = keeper.Get(giveKey.ID)
	assert.NoError(t, err)
	assert.Equal(t, giveKey, *gotKey)
}

func TestFileKeeper_Remove(t *testing.T) {
	tmpDir := createTempDir(t)
	defer removeTempDir(t, tmpDir)

	filePath := tmpDir + "/test.json"
	keeper := NewFileKeeper(filePath)
	giveKey := keys.Key{ID: "foo", Password: "bar", AddedAtUnix: time.Now().Unix()}

	assert.Error(t, keeper.Remove(giveKey.ID))
	assert.NoError(t, keeper.Add(giveKey))

	// re-create instance
	keeper = NewFileKeeper(filePath)

	assert.NoError(t, keeper.Remove(giveKey.ID))
}

// Create temporary directory.
func createTempDir(t *testing.T) string {
	t.Helper()

	tmpDir, err := ioutil.TempDir("", "test-")
	if err != nil {
		t.Fatal(err)
	}

	return tmpDir
}

// Remove temporary directory.
func removeTempDir(t *testing.T, dirPath string) {
	t.Helper()

	if !strings.HasPrefix(dirPath, os.TempDir()) {
		t.Fatalf("Wrong tmp dir path: %s", dirPath)
		return
	}

	if err := os.RemoveAll(dirPath); err != nil {
		t.Fatal(err)
	}
}
