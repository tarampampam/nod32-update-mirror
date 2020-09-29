package get

import (
	"nod32-update-mirror/internal/pkg/config"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates key `get` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	return &cobra.Command{
		Use:   "get",
		Short: "Get one working key",
		Run: func(c *cobra.Command, args []string) {
			l.WithField("config", cfg).Info("WIP")
		},
	}
}
