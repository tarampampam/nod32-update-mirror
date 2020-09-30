package update

import (
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/keys"
	"nod32-update-mirror/internal/pkg/keys/checker"
	"nod32-update-mirror/internal/pkg/keys/crawlers"
	"nod32-update-mirror/internal/pkg/keys/crawlers/androidclub"
	"nod32-update-mirror/internal/pkg/keys/crawlers/eightfornod"
	"nod32-update-mirror/internal/pkg/keys/keepers"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

// NewCommand creates key `update` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "update",
		Short: "Update keys",
		RunE: func(c *cobra.Command, args []string) error {
			var (
				keeper = keepers.NewFileKeeper(cfg.Mirror.FreeKeys.FilePath)
				crwls  = keyCrawlersFactory()
			)

			l.Info("Fresh keys fetching started")
			freshKeys := fetchFreshKeys(l, &crwls)

			if len(freshKeys) > 0 {
				l.WithField("keys count", len(freshKeys)).Info("Fresh keys received. Put keys into storage")
				nowUnix := time.Now().Unix()

				// update 'added at' timestamp
				for i := range freshKeys {
					freshKeys[i].AddedAtUnix = nowUnix
				}

				if err := keeper.Add(freshKeys...); err != nil {
					l.WithError(err).Error("Cannot append keys into storage")

					return err
				}
			} else {
				l.Warn("No one fresh key fetched :(")
			}

			storedKeys, err := keeper.All()
			if err != nil {
				l.WithError(err).Error("Keys reading from storage has been failed")

				return err
			}

			mustBeRemoved := validateKeyIDs(l, storedKeys) // MANY errors here

			if len(mustBeRemoved) > 0 {
				l.WithField("invalid", mustBeRemoved).Info("Invalid keys found. Cleanup storage")

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

func keyCrawlersFactory() []crawlers.Crawler {
	return []crawlers.Crawler{
		eightfornod.NewCrawler(),
		androidclub.NewCrawler(),
	}
}

func fetchFreshKeys(l *logrus.Logger, crwls *[]crawlers.Crawler) keys.Keys {
	var (
		wg     = sync.WaitGroup{}
		mutex  = sync.Mutex{}
		result = make(keys.Keys, 0)
	)

	for i, c := range *crwls {
		wg.Add(1)

		go func(i int, c crawlers.Crawler) {
			l.WithFields(logrus.Fields{
				"target": c.Target(),
				"thread": i,
			}).Debug("Fetching started")

			k, err := c.Fetch()
			if err != nil {
				l.WithFields(logrus.Fields{
					"target": c.Target(),
					"thread": i,
				}).WithError(err).Error("Keys fetching failed")
			} else if k != nil {
				l.WithFields(logrus.Fields{
					"target":     c.Target(),
					"keys count": len(*k),
					"thread":     i,
				}).Debug("Got result")

				if len(*k) > 0 {
					mutex.Lock()
					result = append(result, *k...)
					mutex.Unlock()
				}
			}

			wg.Done()
		}(i, c)
	}

	wg.Wait()

	return result
}

func validateKeyIDs(l *logrus.Logger, in *keys.Keys) []string {
	var (
		wg            = sync.WaitGroup{}
		chk           = checker.New()
		mutex         = sync.Mutex{}
		invalidKeyIDs = make([]string, 0)
	)

	for i := range *in {
		wg.Add(1)

		go func(i int) {
			var (
				keyID       = (*in)[i].ID
				keyPassword = (*in)[i].Password
				logFields   = logrus.Fields{"key id": keyID}
			)

			if keyID != "" && keyPassword != "" {
				if isValid, err := chk.CheckKey(keyID, keyPassword); err != nil {
					l.WithFields(logFields).WithError(err).Warn("Key checking failed")
				} else if !isValid {
					l.WithFields(logFields).Debug("Key is invalid")

					mutex.Lock()
					invalidKeyIDs = append(invalidKeyIDs, keyID)
					mutex.Unlock()
				}
			} else if keyID != "" && keyPassword == "" {
				if isValid, err := chk.CheckLicense(keyID); err != nil {
					l.WithFields(logFields).WithError(err).Warn("License checking failed")
				} else if !isValid {
					l.WithFields(logFields).Debug("License is invalid")

					mutex.Lock()
					invalidKeyIDs = append(invalidKeyIDs, keyID)
					mutex.Unlock()
				}
			}

			wg.Done()
		}(i)
	}

	wg.Wait()

	return invalidKeyIDs
}
