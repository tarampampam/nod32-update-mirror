package key

import (
	"nod32-update-mirror/internal/pkg/cli/key/get"
	"nod32-update-mirror/internal/pkg/cli/key/list"
	"nod32-update-mirror/internal/pkg/cli/key/update"
	"nod32-update-mirror/internal/pkg/config"

	"github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

// NewCommand creates `key` command.
func NewCommand(l *logrus.Logger, cfg *config.Config) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "key",
		Short: "Free license keys (USE FOR EDUCATIONAL OR INFORMATIONAL PURPOSES ONLY!)",
	}

	cmd.AddCommand(
		get.NewCommand(l, cfg),
		list.NewCommand(l, cfg),
		update.NewCommand(l, cfg),
	)

	return cmd
}
