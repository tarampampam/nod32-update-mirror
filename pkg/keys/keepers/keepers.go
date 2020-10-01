package keepers

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"nod32-update-mirror/pkg/keys"
	"os"
	"sync"
)

// Keeper is a storage for keys.
type Keeper interface {
	// All returns all stored keys
	All() (*keys.Keys, error)

	// Get return key with passed key ID
	Get(keyID string) (*keys.Key, error)

	// Remove removes the key with passed key ID
	Remove(keyID string) error

	// Add appends passed key in storage
	Add(key ...keys.Key) error

	// Clear removes all keys
	Clear() error
}

// InMemoryKeeper uses memory as a storage
type InMemoryKeeper struct {
	mutex sync.Mutex
	items map[string]keys.Key
}

// NewInMemoryKeeper creates new in-memory keys keeper.
func NewInMemoryKeeper() InMemoryKeeper {
	return InMemoryKeeper{
		mutex: sync.Mutex{},
		items: make(map[string]keys.Key),
	}
}

// All returns all stored keys in memory.
func (k *InMemoryKeeper) All() (*keys.Keys, error) {
	k.mutex.Lock()
	all := make(keys.Keys, 0, len(k.items))

	for _, key := range k.items {
		all = append(all, key)
	}

	k.mutex.Unlock()

	return &all, nil
}

// Get return key with passed key ID, or error if key does not exists.
func (k *InMemoryKeeper) Get(keyID string) (*keys.Key, error) {
	k.mutex.Lock()
	defer k.mutex.Unlock()

	if key, ok := k.items[keyID]; ok {
		return &key, nil
	}

	return nil, errors.New("key does not exists")
}

// Remove removes the key with passed key ID, or error if key does not exists.
func (k *InMemoryKeeper) Remove(keyID string) error {
	k.mutex.Lock()
	defer k.mutex.Unlock()

	if _, ok := k.items[keyID]; ok {
		delete(k.items, keyID)

		return nil
	}

	return errors.New("key does not exists")
}

// Add appends passed key in storage.
func (k *InMemoryKeeper) Add(key ...keys.Key) error {
	k.mutex.Lock()
	defer k.mutex.Unlock()

	for _, passed := range key {
		k.items[passed.ID] = passed
	}

	return nil
}

// Clear removes all keys.
func (k *InMemoryKeeper) Clear() error {
	k.mutex.Lock()

	for id := range k.items {
		delete(k.items, id)
	}

	k.mutex.Unlock()

	return nil
}

// InMemoryKeeper uses file (in json format) as a persistent keys storage. Each operation will read/write data from
// disk
type FileKeeper struct {
	mutex        sync.Mutex
	filePath     string
	memoryKeeper InMemoryKeeper // as a temporary storage
}

// NewFileKeeper creates keeper that uses file as a persistent storage.
func NewFileKeeper(filePath string) FileKeeper {
	return FileKeeper{
		mutex:        sync.Mutex{},
		memoryKeeper: NewInMemoryKeeper(),
		filePath:     filePath,
	}
}

func (k *FileKeeper) load() error {
	k.mutex.Lock()
	defer k.mutex.Unlock()

	file, err := os.OpenFile(k.filePath, os.O_RDONLY|os.O_CREATE, 0664)
	if err != nil {
		return err
	}

	defer file.Close()

	content, err := ioutil.ReadAll(file)
	if err != nil {
		return err
	}

	if len(content) > 0 {
		data := make(keys.Keys, 0)
		if err := json.Unmarshal(content, &data); err != nil {
			return err
		}

		for _, key := range data {
			if err := k.memoryKeeper.Add(key); err != nil {
				return err
			}
		}
	}

	return nil
}

func (k *FileKeeper) save() error {
	k.mutex.Lock()
	defer k.mutex.Unlock()

	data, err := k.memoryKeeper.All()
	if err != nil {
		return err
	}

	j, err := json.Marshal(data)
	if err != nil {
		return err
	}

	file, err := os.OpenFile(k.filePath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0664)
	if err != nil {
		return err
	}

	defer file.Close()

	if _, err := file.Write(j); err != nil {
		return err
	}

	return nil
}

// All returns all stored keys (data will be loaded from filesystem at first).
func (k *FileKeeper) All() (*keys.Keys, error) {
	if err := k.load(); err != nil {
		return nil, err
	}

	return k.memoryKeeper.All()
}

// Get return key with passed key ID (data will be loaded from filesystem at first).
func (k *FileKeeper) Get(keyID string) (*keys.Key, error) {
	if err := k.load(); err != nil {
		return nil, err
	}

	return k.memoryKeeper.Get(keyID)
}

// Remove removes the key with passed key ID (data will be loaded from filesystem at first and written back at the end).
func (k *FileKeeper) Remove(keyID string) error {
	if err := k.load(); err != nil {
		return err
	}

	if err := k.memoryKeeper.Remove(keyID); err != nil {
		return err
	}

	return k.save()
}

// Add appends passed key in storage (data will be loaded from filesystem at first and written back at the end).
func (k *FileKeeper) Add(key ...keys.Key) error {
	if err := k.load(); err != nil {
		return err
	}

	if err := k.memoryKeeper.Add(key...); err != nil {
		return err
	}

	return k.save()
}

// Clear removes all keys (file on filesystem will be cleared at the end).
func (k *FileKeeper) Clear() error {
	if err := k.memoryKeeper.Clear(); err != nil {
		return err
	}

	return k.save()
}
