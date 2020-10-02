package update

import (
	"errors"
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/fs"
	"nod32-update-mirror/pkg/keys"
	"nod32-update-mirror/pkg/keys/checker"
	"nod32-update-mirror/pkg/keys/crawlers"
	"nod32-update-mirror/pkg/keys/crawlers/androidclub"
	"nod32-update-mirror/pkg/keys/crawlers/eightfornod"
	"nod32-update-mirror/pkg/keys/keepers"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

// NewCommand creates keys `update` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "update",
		Short: "Get fresh free keys (USE FOR DEBUG PURPOSES ONLY!)",
		RunE: func(c *cobra.Command, _ []string) error {
			if err := fs.MkdirAllForFile(cfg.Mirror.FreeKeys.FilePath, 0775); err != nil {
				return err
			}

			keeper := keepers.NewFileKeeper(cfg.Mirror.FreeKeys.FilePath)

			l.Info("Fresh keys fetching started")
			freshKeys := fetchFreshKeys(l)

			if len(freshKeys) > 0 {
				l.WithField("new keys", len(freshKeys)).Info("Fresh keys received. Put keys into storage")

				// update 'added at' timestamp
				nowUnix := time.Now().Unix()
				for i := range freshKeys {
					freshKeys[i].AddedAtUnix = nowUnix
				}

				if err := keeper.Add(freshKeys...); err != nil {
					return errors.New("cannot append keys into storage: " + err.Error())
				}
			} else {
				l.Warn("No one fresh key fetched :(")
			}

			storedKeys, err := keeper.All()
			if err != nil {
				return errors.New("keys reading from storage has been failed: " + err.Error())
			}

			l.WithField("keys in storage", len(*storedKeys)).Info("Keys checking started")
			mustBeRemoved := validateKeyIDs(l, storedKeys, 4, time.Second)

			if len(mustBeRemoved) > 0 {
				l.WithField("invalid keys", len(mustBeRemoved)).Info("Invalid keys found. Cleanup storage")
				l.WithField("keys", mustBeRemoved).Debug("Invalid keys")

				for _, keyID := range mustBeRemoved {
					if err := keeper.Remove(keyID); err != nil {
						l.WithError(err).Error("Cannot remove key from storage")
					}
				}
			}

			return nil
		},
	}
}

func fetchFreshKeys(log *logrus.Logger) keys.Keys {
	var (
		wg     = sync.WaitGroup{}
		mutex  = sync.Mutex{}
		result = make(keys.Keys, 0)
		crwls  = []crawlers.Crawler{
			eightfornod.NewCrawler(),
			androidclub.NewCrawler(),
		}
	)

	for i := range crwls {
		wg.Add(1)

		go func(i int, c crawlers.Crawler) {
			logFields := logrus.Fields{"target": c.Target(), "thread": i}

			log.WithFields(logFields).Debug("Fetching started")

			k, err := c.Fetch()
			if err != nil {
				log.WithFields(logFields).WithError(err).Error("Keys fetching failed")
			} else if k != nil {
				log.WithFields(logFields).WithField("keys", len(*k)).Debug("Complete")

				if len(*k) > 0 {
					mutex.Lock()
					result = append(result, *k...)
					mutex.Unlock()
				}
			}

			wg.Done()
		}(i, crwls[i])
	}

	wg.Wait()

	return result
}

func validateKeyIDs(log *logrus.Logger, in *keys.Keys, maxRetry int, rDelay time.Duration) []string { //nolint:funlen
	var (
		wg                   = sync.WaitGroup{}
		chk                  = checker.New()
		mutex, invalidKeyIDs = sync.Mutex{}, make([]string, 0)
	)

	for i := range *in {
		wg.Add(1)

		go func(i int) {
			var (
				keyID, keyPassword = (*in)[i].ID, (*in)[i].Password
				logFields          = logrus.Fields{"key id": keyID, "thread": i}
				isValid            bool
				checkingErr        error
			)

		retryLoop:
			for t := 0; t < maxRetry; t++ {
				switch {
				case keyID != "" && keyPassword != "":
					isValid, checkingErr = chk.CheckKey(keyID, keyPassword)
				case keyID != "" && keyPassword == "":
					isValid, checkingErr = chk.CheckLicense(keyID)
				default:
					log.WithFields(logFields).Error("unsupported key properties state")

					break retryLoop
				}

				switch {
				case checkingErr != nil:
					log.
						WithFields(logFields).
						WithField("try", t+1).
						WithError(checkingErr).
						Warn("Key/license checking failed")

					time.Sleep(rDelay)
				case !isValid:
					log.WithFields(logFields).Debug("Key/license is invalid")

					mutex.Lock()
					invalidKeyIDs = append(invalidKeyIDs, keyID)
					mutex.Unlock()

					break retryLoop
				case isValid:
					break retryLoop
				}

				if t == maxRetry-1 {
					log.WithFields(logFields).Error("Key/license cannot be checked")
				}
			}

			wg.Done()
		}(i)
	}

	wg.Wait()

	return invalidKeyIDs
}
