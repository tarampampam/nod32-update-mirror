package update

import (
	"errors"
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/fs"
	"nod32-update-mirror/pkg/nod32mirror"
	"os"
	"path"
	"strings"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

type remoteServerProps struct {
	url, username, password string
}

const tempUpdateDirName = ".last_update"

// NewCommand creates `update` command.
func NewCommand(log *logrus.Logger, cfg *config.Config) *cobra.Command { //nolint:funlen
	return &cobra.Command{
		Use:   "update",
		Short: "Update mirror",
		RunE: func(c *cobra.Command, _ []string) error {
			m := nod32mirror.NewMirrorer()

			var (
				versionFile  *nod32mirror.VersionFile
				remoteServer *remoteServerProps
			)

			// select server for a working
			for _, srv := range cfg.Mirror.Servers {
				log.WithField("server", srv.URL).Info("Server checking")
				var err error
				if versionFile, err = m.GetRemoteVersionFile(strings.TrimRight(srv.URL, "/") + "/update.ver"); err != nil {
					log.
						WithError(err).
						WithField("server", srv.URL).
						Warn("Version file on server not accessible or broken")
				} else {
					remoteServer = &remoteServerProps{
						url:      srv.URL,
						username: srv.Username,
						password: srv.Password,
					}

					break
				}
			}

			if versionFile == nil || remoteServer == nil {
				return errors.New("no one server can be used for mirroring")
			}

			// at first of all - we must create directory for updating files, if needed
			if _, err := os.Stat(cfg.Mirror.Path); os.IsNotExist(err) {
				log.WithField("path", cfg.Mirror.Path).Info("Create directory for updating files")
				if err := os.MkdirAll(cfg.Mirror.Path, 0775); err != nil {
					return err
				}
			}

			tempUpdateDir := path.Join(cfg.Mirror.Path, tempUpdateDirName)

			// if temporary mirror directory does NOT exist - this is a "fresh" update run
			if _, err := os.Stat(tempUpdateDir); os.IsNotExist(err) {
				log.
					WithFields(logrus.Fields{"from": cfg.Mirror.Path, "to": tempUpdateDir}).
					Info("Making a copy of directory with existing updating files")
				if err := fs.CopyDirectoryRecursive(cfg.Mirror.Path, tempUpdateDir, func(relativeFilePath string) bool {
					return strings.HasSuffix(relativeFilePath, "update.ver")
				}); err != nil {
					return err
				}
			} else {
				log.WithField("directory", tempUpdateDir).Info("Resume mirroring")
			}

			// start remote mirror sync
			for _, target := range versionFile.Sections {
				log.Info(target.File)
			}

			return nil
		},
	}
}
