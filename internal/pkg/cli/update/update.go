package update

import (
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/pkg/nod32mirror"
	"strings"

	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

type remoteServerProps struct {
	url, username, password string
}

// NewCommand creates `update` command.
func NewCommand(log *logrus.Logger, cfg *config.Config) *cobra.Command {
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

			log.Info(remoteServer)

			return nil
		},
	}
}
