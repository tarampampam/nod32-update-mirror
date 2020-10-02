package fs

import (
	"errors"
	"io"
	"os"
	"path"
	"path/filepath"
	"strings"
	"sync"
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

// CopyDirectoryRecursive a recursive directory copy in a 2 steps - firstly directories will br created, and after that
// all files will be copied asynchronously.
func CopyDirectoryRecursive(src, dest string, skipFileFn func(relativeFilePath string) bool) error { //nolint:funlen
	if info, err := os.Stat(src); os.IsNotExist(err) {
		return errors.New("not exists: " + src)
	} else if !info.IsDir() {
		return errors.New("is not directory: " + src)
	}

	if _, err := os.Stat(dest); !os.IsNotExist(err) {
		return errors.New("already exists: " + dest)
	}

	var (
		// all paths is relative
		planDirs  = make(map[string]os.FileInfo)
		planFiles = make(map[string]os.FileInfo)
	)

	if err := filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relative := strings.TrimPrefix(path, src)

		if info.IsDir() {
			planDirs[relative] = info
		} else if info.Mode().IsRegular() && !skipFileFn(relative) {
			planFiles[relative] = info
		}

		return nil
	}); err != nil {
		return err
	}

	// first run - create directories (sync)
	for p, info := range planDirs {
		if info.IsDir() {
			if err := os.MkdirAll(path.Join(dest, p), info.Mode()); err != nil {
				return err
			}
		}
	}

	var (
		wg         = sync.WaitGroup{}
		copyErrors = make(chan error)
		wgDone     = make(chan bool)
	)

	// second run - copy files (async)
	for srcPath, srcFileInfo := range planFiles {
		wg.Add(1)

		go func(from, to string, info os.FileInfo) {
			defer wg.Done()

			source, err := os.OpenFile(from, os.O_RDONLY, info.Mode())
			if err != nil {
				copyErrors <- err
				return
			}
			defer source.Close()

			destination, err := os.OpenFile(to, os.O_WRONLY|os.O_CREATE, info.Mode())
			if err != nil {
				copyErrors <- err
				return
			}
			defer destination.Close()

			if _, err := io.Copy(destination, source); err != nil {
				copyErrors <- err
				return
			}
		}(path.Join(src, srcPath), path.Join(dest, srcPath), srcFileInfo)
	}

	go func() {
		wg.Wait()
		close(wgDone)
	}()

	// wait until either WaitGroup is done or an error is received through the channel
	select {
	case <-wgDone:
		break
	case err := <-copyErrors:
		return err
	}

	return nil
}
