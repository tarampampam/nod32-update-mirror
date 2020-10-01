package keys

import (
	"nod32-update-mirror/internal/pkg/cli/keys/list"
	"nod32-update-mirror/internal/pkg/cli/keys/update"
	"nod32-update-mirror/internal/pkg/config"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates `key` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "keys",
		Short: "License keys",
	}

	cmd.AddCommand(
		list.NewCommand(l, cfg),
		update.NewCommand(l, cfg),
	)

	return cmd
}
