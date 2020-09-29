package serve

import (
	"nod32-update-mirror/internal/pkg/config"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates `serve` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "serve",
		Short: "Start HTTP server for mirrored files",
		Run: func(c *cobra.Command, args []string) {
			l.WithField("config", cfg).Info("WIP")
		},
	}
}
