package fs

import (
	"os"
	"path"
)

// MkdirAllForFile creates directory (with all nested directories) for keys keeper (if needed).
func MkdirAllForFile(filePath string, perm os.FileMode) error {
	// create directory (with all nested directories) for keys keeper (if needed)
	fileDirPath := path.Dir(filePath)

	if _, err := os.Stat(fileDirPath); os.IsNotExist(err) {
		if err := os.MkdirAll(fileDirPath, perm); err != nil {
			return err
		}
	}

	return nil
}
